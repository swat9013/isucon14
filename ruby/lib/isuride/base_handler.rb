# frozen_string_literal: true

require 'mysql2'
require 'mysql2-cs-bind'
require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'
require 'estackprof'
require 'dalli'

# mysql2-cs-bind gem にマイクロ秒のサポートを入れる
module Mysql2CsBindPatch
  def quote(rawvalue)
    if rawvalue.respond_to?(:strftime)
      "'#{rawvalue.strftime('%Y-%m-%d %H:%M:%S.%6N')}'"
    else
      super
    end
  end
end
Mysql2::Client.singleton_class.prepend(Mysql2CsBindPatch)

module Isuride
  class BaseHandler < Sinatra::Base
    INITIAL_FARE = 500
    FARE_PER_DISTANCE = 100

    # profile
    use Estackprof::Middleware

    # logging
    enable :logging
    Dir.mkdir("log") unless File.exist?("log")
    access_log = File.new("log/access.log","a+")
    access_log.sync = true
    use Rack::CommonLogger, access_log

    app_log = File.new("log/application.log", "a+")
    app_log.sync = true
    app_logger = Logger.new(app_log)

    # curl_logger = Logger.new('log/curl.log')

    before do
      env["rack.logger"] = app_logger

      #   # テスト作成用
      # # リクエストヘッダーの取得
      # http_headers = request.env.select { |k, v| k.start_with?('HTTP_') }

      # # cURL形式でログ出力
      # curl_command = ["curl -X #{request.request_method}"]

      # # # ヘッダーの追加
      # # http_headers.each do |k, v|
      # #   header_name = k.sub('HTTP_', '').split('_').map(&:capitalize).join('-')
      # #   curl_command << "-H '#{header_name}: #{v}'"
      # # end

      # # cookieがドメイン指定されている場合に必要
      # curl_command << "--resolve '#{http_headers['HTTP_HOST']}:8080:127.0.0.1'"

      # curl_command << "-b cookie.txt -c cookie.txt"
      # # POSTデータの追加
      # if request.post?
      #   curl_command << "-d '#{request.body.read}'"
      #   request.body.rewind
      # end

      # # URLの追加
      # curl_command << "'#{request.url}'"

      # # ログに出力
      # # curl_logger.info "Request Headers: #{http_headers}"
      # curl_logger.info "#{curl_command.join(' ')}"
      # # curl_logger.info "Parameters: #{params}"
    end

    set :show_exceptions, :after_handler

    class HttpError < Sinatra::Error
      attr_reader :code

      def initialize(code, message)
        super(message || "HTTP error #{code}")
        @code = code
      end
    end

    error StandardError do
      e = env['sinatra.error']
      logger.error(e)
      status e.code
      json(error: e.message)
    end

    error HttpError do
      e = env['sinatra.error']
      logger.warn(e)
      status e.code
      json(message: e.message)
    end

    helpers Sinatra::Cookies

    helpers do
      # 例:
      # with_memcached(key) do
      #   process()
      # end
      def cache_client
        Thread.current[:cache_client] ||= Dalli::Client.new('127.0.0.1:11211')
      end

      def with_memcached(cache_key)
        begin
          cached_response = cache_client.get(cache_key)
          return cached_response if cached_response
        rescue Dalli::RingError
        end

        actual = yield

        begin
          cache_client.set(cache_key, actual)
        rescue Dalli::RingError
        end

        actual
      end

      def delete_memcached(cache_key)
        begin
          cache_client.delete(cache_key)
        rescue Dalli::RingError
        end
      end

      def bind_json(data_class)
        body = JSON.parse(request.body.tap(&:rewind).read, symbolize_names: true)
        data_class.new(**data_class.members.map { |key| [key, body[key]] }.to_h)
      end

      def db
        Thread.current[:db] ||= connect_db
      end

      def connect_db
        Mysql2::Client.new(
          host: ENV.fetch('ISUCON_DB_HOST', '127.0.0.1'),
          port: ENV.fetch('ISUCON_DB_PORT', '3306').to_i,
          username: ENV.fetch('ISUCON_DB_USER', 'isucon'),
          password: ENV.fetch('ISUCON_DB_PASSWORD', 'isucon'),
          database: ENV.fetch('ISUCON_DB_NAME', 'isuride'),
          symbolize_keys: true,
          cast_booleans: true,
          database_timezone: :utc,
          application_timezone: :utc,
        )
      end

      def db_transaction(&block)
        db.query('BEGIN')
        ok = false
        begin
          retval = block.call(db)
          db.query('COMMIT')
          ok = true
          retval
        ensure
          unless ok
            db.query('ROLLBACK')
          end
        end
      end

      def time_msec(time)
        time.to_i*1000 + time.usec/1000
      end

      def get_latest_ride_status(tx, ride_id)
        tx.xquery('SELECT status FROM ride_statuses WHERE ride_id = ? ORDER BY created_at DESC LIMIT 1', ride_id).first.fetch(:status)
      end

      # マンハッタン距離を求める
      def calculate_distance(a_latitude, a_longitude, b_latitude, b_longitude)
        (a_latitude - b_latitude).abs + (a_longitude - b_longitude).abs
      end

      def calculate_fare(pickup_latitude, pickup_longitude, dest_latitude, dest_longitude)
        metered_fare = FARE_PER_DISTANCE * calculate_distance(pickup_latitude, pickup_longitude, dest_latitude, dest_longitude)
        INITIAL_FARE + metered_fare
      end

      def generate_id
        # 現在時刻を取得
        current_time = Time.now
        # 時刻を指定フォーマットで文字列化
        formatted_time = current_time.strftime('%Y%m%d%H%M%S%N')
        # ゼロ埋めして26桁にする
        result = formatted_time.ljust(26, '0') # 左詰めで右側を0埋め
      end
    end
  end
end

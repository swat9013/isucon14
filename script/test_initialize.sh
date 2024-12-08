#!/bin/sh
set -e

# [初参戦のISUCONで予選敗退した話 (ヽ´ω`) < 22位 - aeroastroの日記](https://aeroastro.hatenablog.com/entry/2018/09/18/180602)
# 正規表現
# I,.* INFO -- :
# curlの出力を制御
# -o /dev/null -w '%{http_code} %{url}\n' -s

# シナリオ
curl -X POST --resolve 'xiv.isucon.net:8080:127.0.0.1' -b cookie.txt -c cookie.txt -d '{"payment_server":"http://43.206.99.106:12345"}' 'http://xiv.isucon.net:8080/api/initialize'

echo "\n【SUCCESS】正常に実行されました"
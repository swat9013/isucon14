#!/bin/sh -eux

cd "$(dirname "$0")"/../

export TZ=Asia/Tokyo
log_dir=logs/ruby/$(date +"%Y%m%d_%H%M%S")
mkdir -p "${log_dir}"
cd ruby
estackprof list -f chair_handler.rb > ../"${log_dir}"/chair_handler_list.txt
estackprof top -p chair_handler.rb -l 30 > ../"${log_dir}"/chair_handler_top.txt
estackprof list -f owner_handler.rb > ../"${log_dir}"/owner_handler_list.txt
estackprof top -p owner_handler.rb -l 30 > ../"${log_dir}"/owner_handler_top.txt
estackprof list -f payment_gateway.rb > ../"${log_dir}"/payment_gateway_list.txt
estackprof top -p payment_gateway.rb -l 30 > ../"${log_dir}"/payment_gateway_top.txt
estackprof list -f internal_handler.rb > ../"${log_dir}"/internal_handler_list.txt
estackprof top -p internal_handler.rb -l 30 > ../"${log_dir}"/internal_handler_top.txt
estackprof flamegraph
cp -r ./tmp ../"${log_dir}"/logs

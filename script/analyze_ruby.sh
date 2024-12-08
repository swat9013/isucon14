#!/bin/sh -eux

cd "$(dirname "$0")"/../

export TZ=Asia/Tokyo
log_dir=logs/ruby/$(date +"%Y%m%d_%H%M%S")
mkdir -p "${log_dir}"
cd ruby
estackprof list -f app.rb > ../"${log_dir}"/list.txt
estackprof top -p app.rb -l 30 > ../"${log_dir}"/top.txt
estackprof flamegraph
cp -r ./tmp ../"${log_dir}"/logs

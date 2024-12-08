#!/bin/sh -eux

cd "$(dirname "$0")"/../

export TZ=Asia/Tokyo
log_dir=logs/mysql/$(date +"%Y%m%d_%H%M%S")
mkdir -p "${log_dir}"
sudo pt-query-digest /var/log/mysql/mysql-slow.log > "${log_dir}"/pt.log
sudo cp /var/log/mysql/mysql-slow.log "${log_dir}"/mysql-slow.log

sudo systemctl restart mysql

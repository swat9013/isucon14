#!/bin/sh -eux

cd "$(dirname "$0")"/../

export TZ=Asia/Tokyo
log_dir=logs/nginx/$(date +"%Y%m%d_%H%M%S")
mkdir -p "${log_dir}"
sudo alp json --sort sum -r --file /var/log/nginx/access.log > "${log_dir}"/alp.log

sudo cp /var/log/nginx/access.log "${log_dir}"/access.log
sudo nginx -s reload

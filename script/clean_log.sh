#!/bin/sh

cd "$(dirname "$0")"/../ || exit

set -x
sudo sh -c "echo > /var/log/mysql/mysql-slow.log"
sudo sh -c "echo > /var/log/nginx/access.log"
rm -r ~/webapp/ruby/tmp
sh -c "echo > ~/webapp/ruby/log/access.log"
sh -c "echo > ~/webapp/ruby/log/application.log"
sh -c "echo > ~/webapp/ruby/log/curl.log"
set +x


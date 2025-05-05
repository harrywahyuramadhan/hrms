#!/bin/bash

set -e

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
    bench setup requirements
    bench start
    exit 0
fi

echo "Creating new bench..."
bench init --frappe-branch version-15 --skip-redis-config-generation --python python3 frappe-bench
cd frappe-bench

bench set-config -g redis_cache redis://redis:6379
bench set-config -g redis_queue redis://redis:6379
bench set-config -g redis_socketio redis://redis:6379
bench set-config -g db_host mariadb

bench get-app erpnext --branch version-15
bench get-app hrms --branch version-15

echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb --silent; do
  sleep 1
done

bench new-site hrms.localhost \
  --mariadb-root-password 123 \
  --admin-password admin \
  --no-mariadb-socket

bench --site hrms.localhost install-app erpnext
bench --site hrms.localhost install-app hrms

bench --site hrms.localhost set-config developer_mode 1
bench --site hrms.localhost enable-scheduler
bench --site hrms.localhost clear-cache
bench use hrms.localhost

yarn install --cwd apps/frappe
bench setup requirements

bench start

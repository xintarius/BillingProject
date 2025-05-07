#!/bin/sh

set -e

export PATH="/usr/local/bundle/bin:/usr/local/bin:$PATH"

mkdir -p tmp log
chmod -R 777 tmp log

if [ "$RUN_CRON" = "true" ]; then
  echo "[scheduler] Updating crontab with whenever..."
  bundle exec whenever --update-crontab
  echo "[scheduler] Starting cron..."
  rm -f /var/run/crond.pid
  cron -f
fi

exec "$@"

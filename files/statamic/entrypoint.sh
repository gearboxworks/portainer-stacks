#!/usr/bin/env sh
set -e
if [ ! -L /var/www/html/storage ]; then
  rm -rf /var/www/html/storage
  ln -s /var/statamic/storage /var/www/html/storage
fi
exec supervisord -c /etc/supervisor/supervisord.conf

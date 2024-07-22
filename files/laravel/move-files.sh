#!/usr/bin/env bash
set -e

if ! [ -d /var/laravel/laravel.local ]; then
  # All files already moved
  exit 0
fi

# Ensure directory is empty
rm -rf /var/www/html/*

# Move all files and directories including hidden
# ones — excluding . and .. — to serve directory.
shopt -s dotglob
mv /var/laravel/laravel.local/* /var/www/html/
shopt -u dotglob

chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html/bootstrap/cache
find /var/www/html -type f -exec chmod 644 {} \;
find /var/www/html -type d -exec chmod 755 {} \;

# Remove temporary build directory
rm -rf /var/laravel/laravel.local

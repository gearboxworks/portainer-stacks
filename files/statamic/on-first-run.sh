#!/usr/bin/env bash
set -e

if ! [ -d /var/statamic/statamic.local ]; then
  # All files already moved
  exit 0
fi

function move_files {
  cd /var

  # Ensure directory is empty
  rm -rf /var/www/html/*

  # Make the public directory
  mkdir /var/www/html/public

  # Set to a "provisioning" page
  cp /var/statamic/provisioning.html /var/www/html/public/index.html

  # Move all files and directories including hidden
  # ones — excluding . and .. — to serve directory.
  rsync -a \
    --remove-source-files \
      /var/statamic/statamic.local/ \
      /var/www/html/ \
    && find /var/statamic/statamic.local/ \
        -type d \
        -empty \
        -delete

  chown -R www-data:www-data /var/www/html
  chmod -R 775 /var/www/html/bootstrap/cache
  chown -R www-data:www-data /var/statamic/storage
  chmod -R 775 /var/statamic/storage

  find /var/www/html -type f -exec chmod 644 {} \;
  find /var/www/html -type d -exec chmod 755 {} \;

  # Remove "provisioning" page
  rm -rf /var/www/html/public/index.html

  # Remove temporary build directory
  rm -rf /var/statamic/statamic.local

}

move_files

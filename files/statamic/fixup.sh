#!/usr/bin/env bash

# Add GENERATE_HTTPS=true to .env to support
# `./app/Providers/HttpsServiceProvider.php`
# See https://stackoverflow.com/a/61313133/102699
function fix_https {

  cd /var/statamic/statamic.local || exit 1
  sed -i "1i GENERATE_HTTPS=true" .env

}

# Set APP_URL in both `.env` and `./config/app.php`
function fix_app_url {
  local file
  local search_text
  local replace_text

  search_text="http://localhost"
  replace_text="https://statamic.local"

  cd /var/statamic/statamic.local || exit 1

  sed -i "s|${search_text}|${replace_text}|" .env
  sed -i "s|${search_text}|${replace_text}|" ./config/app.php

}

# Create a user file at /var/statamic/statamic.local/users/admin@statamic.local.yaml
# which will ultimately be copied over to /var/www/html/users/admin@statamic.local.yaml
#
#   USERNAME=admin@statamic.local
#   PASSWORD=change_me
#
function fix_user_id {
  local file
  local search_text
  local replace_text

  file="admin@statamic.local.yaml"

  cd /var/statamic/statamic.local/users/ || exit 1

  sed -i "s|{{id}}|$(cat /proc/sys/kernel/random/uuid)|" "${file}"
}

fix_https
fix_app_url
fix_user_id

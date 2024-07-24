#!/usr/bin/env bash

# Add `\Illuminate\Support\Facades\URL::forceScheme('https');`
# to boot function in `./app/Providers/AppServiceProvider.php`
# See https://stackoverflow.com/a/61313133/102699
function fix_https {
  local file
  local namespace
  local func_def
  local func_call
  local use_stmt

  cd /var/statamic/statamic.local || exit 1

  file="./app/Providers/AppServiceProvider.php"
  namespace="namespace App\\\\Providers;"
  func_def="public function boot(): void"
  use_stmt="use Illuminate\\\\Support\\\\Facades\\\\URL;"
  func_call="\\\\tURL::forceScheme('https');"

  sed -i "/${namespace}/ {
    n
    a ${use_stmt}
  }" "${file}"

  sed -i "/${func_def}/ {
    n
    a ${func_call}
  }" "${file}"
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

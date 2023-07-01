#!/usr/bin/env bash

function cat_pass {
  cat /tmp/provision/.password.txt
}

function sudo_chmod {
  local perm="$1"
  local filepath="$2"

  cat_pass | sudo -S -p "" chmod "${perm}" "${filepath}"
}

function sudo_mkdir {
  local filepath="$1"

  cat_pass | sudo -S -p "" mkdir -p "${filepath}"
}

function sudo_chown {
  local owner="$1"
  local filepath="$2"

  cat_pass | sudo -S -p "" chown "${owner}" "${filepath}"
}

function sudo_tee {
  local filepath="$1"

  cat_pass | sudo -S -p "" tee "${filepath}"
}

function sudo_cp {
  local from="$1"
  local to="$2"

  cat_pass | sudo -S -p "" cp -R "${from}" "${to}"
}
#!/usr/bin/env bash

source /tmp/provision/shared.sh

function main {
  # Get the parameter which should be a perms.sh somewhere in /tmp/provision/*
  local perms_sh="$1"
  # Strip off the `/tmp/provision`
  local filepath="${perms_sh#"/tmp/provision"}"
  local dirpath

  if [ "" == "${filepath}" ] ; then
    # Nothing to do here
    return
  fi

  # Get the directory perms.sh is designed to work on
  dirpath="$(dirname "${filepath}")"

  # Change to that directory
  cd "${dirpath}" \
    || ( echo "Failed to change directory to ${dirpath}" && exit 1)

  if ! [ -x "${perms_sh}" ] ; then
    # Add the execute permission, if it does not already have it
    sudo_chmod +x "${perms_sh}"
  fi

  # Run it which should apply whatever permissions are needed
  # to files and subdirectories in the $dirpath
  "${perms_sh}"

}

main "$1"


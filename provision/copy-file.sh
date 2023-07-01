#!/usr/bin/env bash

source /tmp/provision/shared.sh

function main {
  # Get the param which should be somewhere in /tmp/rootdir/*
  local tmp_filepath="$1"
  # Strip off the `/tmp/rootdir`
  local filepath="${tmp_filepath#"/tmp/rootdir"}"
  local basefile

  if [ "" == "${filepath}" ] ; then
    # Nothing to do here
    return
  fi

  basefile="$(basename "${filepath}")"

  if [ "perms.sh" == "${basefile}" ] ; then
    # It is our own `perms.sh` so we don't need to do anything here
    return
  fi

  if [ -d "${tmp_filepath}" ] ; then
    # It is a directory; do we need to create it?
    if ! [ -d "${filepath}" ] ; then
      # The directory does not exist, so create it
      sudo_mkdir "${filepath}"
      sudo_chown "root:root" "${filepath}"
    fi
    return
  fi

  if ! [ -f "${tmp_filepath}" ] ; then
    # It is not a file so we don't need to do anything
    # (Could this even happen?)
    return
  fi

  if [ -f "${filepath}" ] ; then
    # The file already exists so we don't need to do anything
    return
  fi

  # The file does not exist, so copy it
  sudo_cp "${tmp_filepath}" "${filepath}"
  sudo_chown "root:root" "${filepath}"

}

main "$1"


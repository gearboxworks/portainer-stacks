#!/usr/bin/env bash

# NOT TESTED

# Run this on Linux VM to connect to external share (i.e. such as on macOS)
# THIS IS ACTUALLY NOT NEEDED.
# DOCKER COMPOSE MANAGES THIS WITH AN EXTERNAL MOUNT.

#function is_mounted() {
#  local text
#  text="$1"
#  mount 2>&1 | grep -q "${text}" && echo yes || echo no
#}

function main() {
  local host
  local share
  local options
  local remote_dir
#  local local_dir
  host="$1"
  share="$2"

  read -sp "Enter password for external share '$1/$2': " password

  printf "username=%s\npassword=%s\n" "$(whoami)" "${password}" \
    | sudo tee -a /etc/cifs-credentials >/dev/null

  remote_dir="//${host}/${share}"
  options="credentials=/etc/cifs-credentials,vers=3.0,uid=0,gid=0,file_mode=0755,dir_mode=0755"

  docker volume create \
    --driver local \
    --opt type=cifs \
    --opt device="${remote_dir}" \
    --opt o="${options}" \
    "${share}"


# This is as if done via Bash mount command
#
#  local_dir="/var/lib/docker/volumes/${share}"
#  if ! is_mounted "${remote_dir}"; then
#    # Add to /etc/fstab so it will be recreated after booting
#    sudo mount -t cifs -o ${options} "${remote_dir}" "${local_dir}"
#  fi
#
#  if grep -q "${remote_dir}" /etc/fstab; then
#    # Add to /etc/fstab so it will be recreated after booting
#    echo "${remote_dir} ${local_dir} cifs ${options} 0 0" \
#      | sudo tee -a /etc/fstab >/dev/null
#  fi

}

main "$1" "$2"

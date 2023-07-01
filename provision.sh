#!/usr/bin/env bash

REMOTE_SYSTEM="containers.local"



function main {
  local password

  read -r -s -p "Enter remote sudo password: " password
  echo

  echo "${password}" > provision/.password.txt

  # First make sure the files do NOT exist on the server
  ssh "${REMOTE_SYSTEM}" 'bash -s' <<'ENDSSH'
    rm -rf /tmp/provision
    rm -rf /tmp/rootdir
ENDSSH

  # Copy files in `host:/provision` to `remote:/tmp/provision`
  scp -r -q provision "${REMOTE_SYSTEM}":/tmp/provision

  # Delete password locally after uploading to remote system
  rm provision/.password.txt

  # Copy files in `host:/rootdir` to `remote:/tmp/rootdir`
  scp -r -q rootdir "${REMOTE_SYSTEM}":/tmp/rootdir

  ssh "${REMOTE_SYSTEM}" 'bash -s' <<'ENDSSH'
    for file in $(find /tmp/rootdir) ; do
      # Copy any files from rootdir to
      /tmp/provision/copy-file.sh "${file}"
    done

    for file in $(find /tmp/provision | grep perms.sh) ; do
      # Ensure all perms.sh can be executed
      /tmp/provision/run-perms.sh "${file}"
    done

    rm -rf /tmp/provision
    rm -rf /tmp/rootdir
ENDSSH

}
echo "Initiating provision of ${REMOTE_SYSTEM}:"
main
echo "Provision complete (assuming no errors appeared above)"
}
#!/usr/bin/env bash

function main {
  local tables="$1"
  local socket="/tmp/ssh-control-socket"
  local host="containers.local"
  local my_cnf="/root/.my.cnf"
  local sql_file
  local target
  local cfg_script="/tmp/mysql-config-script"

  if [ "${tables}" == "all" ]; then
    target="--databases wordpress"
    sql_file="wordpress.sql"
  else
    target="wordpress ${tables}"
    sql_file="${tables}.sql"
  fi

  # Ensure there is not previous socket in-use
  rm -f "${socket}"

  echo Downloading "${sql_file}"

  # Create a script to ensure configuration exists
  cat <<EOF > "${cfg_script}"
touch "${my_cnf}"
chmod 600 "${my_cnf}"
if ! grep -q "^\[mysqldump\]" "${my_cnf}"; then
  (
    echo "[mysqldump]"
    echo "user=root"
    echo "password=wordpress"
  ) >> "${my_cnf}"
fi
EOF
  chmod +x "${cfg_script}"

  echo "Creating a socket"
  ssh -fN -M -S "${socket}" "${host}" -o ControlMaster=yes

  echo Uploading config script
  scp -o ControlPath="${socket}" "${cfg_script}" "${host}":"${cfg_script}"

  # shellcheck disable=SC2087
  ssh -q -o ControlPath="${socket}" "${host}" <<ENDSSH
echo Copying MySQL config script
docker cp "${cfg_script}" wp-db-1:"${cfg_script}"
echo Running MySQL config script
docker exec wp-db-1 sh "${cfg_script}"
echo Dumping database
docker exec wp-db-1 \
  mysqldump --add-drop-table \
    --result-file "${sql_file}" \
    ${target}
echo Copying database out of MySQL container
docker cp wp-db-1:"${sql_file}" "${sql_file}"
ENDSSH

  echo Downloading database
  scp -o ControlPath="${socket}" "${host}":"${sql_file}" "${sql_file}"

  rm -f "${cfg_script}"

}

tables="$1"
if [ "${tables}" == "" ]; then
  tables=all
fi

main "${tables}"

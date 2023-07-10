#!/usr/bin/env bash

function main {
  local dbname="$1"
  local socket="/tmp/ssh-control-socket"
  local host="containers.local"
  local sql_file
  local my_cnf="/root/.my.cnf"
  local cfg_script
  local cfg_script="/tmp/mysql-config-script"

  if [ "${dbname}" == "all" ]; then
    sql_file="wordpress.sql"
  else
    sql_file="${dbname}"
  fi

  # Ensure there is not previous socket in-use
  rm -f "${socket}"

  echo Uploading "${sql_file}"

  # Create a script to ensure configuration exists
  cat <<EOF > "${cfg_script}"
touch "${my_cnf}"
chmod 600 "${my_cnf}"
if ! grep -q "^\[mysql\]" "${my_cnf}"; then
  (
    echo "[mysql]"
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

  echo Uploading database
  scp -o ControlPath="${socket}"  "${sql_file}" "${host}":"${sql_file}"

  # shellcheck disable=SC2087
  ssh -q -o ControlPath="${socket}" "${host}" <<ENDSSH
echo Copying MySQL config script
docker cp "${cfg_script}" wp-db-1:"${cfg_script}"

echo Running MySQL config script
docker exec wp-db-1 sh "${cfg_script}"

echo Copying database into MySQL container
docker cp "${sql_file}" wp-db-1:"${sql_file}"

echo Importing database
docker exec wp-db-1 mysql -e "source ${sql_file}"
ENDSSH

  rm -f "${cfg_script}"

}

dbname="$1"
if [ "${dbname}" == "" ]; then
  dbname=all
fi

main "${dbname}"


#!/usr/bin/env bash

# TODO: Get IP address from `ip addr`
HOST_IP_ADDRESS="192.168.1.110"
HOST_PORT="8081"
TRAEFIK_ROUTERS_API_URL="http://${HOST_IP_ADDRESS}:${HOST_PORT}/api/http/routers"
CACHE_FILE="/etc/traefik/traefik-mdns.json"
DEBUG=0

function debug_msg {
  local msg="$1"
  if [ $DEBUG -eq 1 ] ; then
    printf "%s" "${msg}"
  fi
}

function publish_domain {
  local host_ip="$1"
  local domain="$2"

  /usr/bin/avahi-publish -a "${domain}" -R "${host_ip}" &
}

function get_cached {
  if ! [ -f "${CACHE_FILE}" ] ; then
    echo '{}' > "${CACHE_FILE}"
  fi
  < "${CACHE_FILE}" \
    jq '.[] | select(.rule|contains("Host(`"))|.rule' \
        | tr '`' ' ' \
        | awk '{print$2}' \
        | sort \
        | uniq \
        | tr "\n" ' '

}

function current_iso8601_datetime {
  # Example: 2023-06-29T05:52:18Z where Z means UTC
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

function get_routers {
  curl --silent "${TRAEFIK_ROUTERS_API_URL}"
}

function get_published {
  pgrep -a avahi-publish | awk '{print $4}' | tr "\n" ' '
}

function kill_published {
  pgrep avahi-publish | xargs kill -9
}

function get_defined {
  local json="$1"

  jq --null-input \
    --argjson routers "${json}" \
    '$routers | .[] | select(.rule|contains("Host(`"))|.rule' \
      | tr '`' ' ' \
      | awk '{print$2}' \
      | sort \
      | uniq \
      | tr "\n" ' '
}

function main() {
  local space=' '
  local updated=0
  local routers
  local published
  local cached
  local defined
  local domain


  cached="${get_cached)"
  routers="$(get_routers)"
  if [ "${routers}" == "" ] ; then
    printf "\nWarning: Unable to reach %s" "${TRAEFIK_ROUTERS_API_URL}" >&2
    # TODO Load cached values from JSON file
    #      Omit those last seen more than 24 hour ago
  fi
  published="${space}$(get_published)${space}"
  defined="$(get_defined "${routers}")"
  for domain in $defined; do
    debug_msg "$(printf "\nChecking if %s is published..." "${domain}")"
    # Loop through $defined and if not in $published then publish
    if [[ "${published}" =~ ${space}${domain}${space} ]] ; then
      # As it is published, look to the next one
      # Update JSON with last seen time
      debug_msg "already published."
      continue
    fi
    printf "\nPublishing %s" "${domain}"
    if ! publish_domain "${HOST_IP_ADDRESS}" "${domain}"; then
      printf "\nError: Unable to publish %s" "${domain}" >&2
    fi
    updated=1
    # Update JSON with newly published domain and time
  done
  if [ $updated -eq 1 ]; then
    printf "\n"
  fi
}

main

}
#!/usr/bin/env bash

pgrep -a avahi-publish

HOST_IP_ADDRESS="$(hostname -I | awk '{print$1}')"
HOST_PORT="8081"
TRAEFIK_ROUTERS_API_URL="http://${HOST_IP_ADDRESS}:${HOST_PORT}/api/http/routers"
CACHE_FILE="/etc/traefik/traefik-mdns.json"

function is_debug {
  local is_debug="$1"
  if [ "debug" == "${is_debug}" ] ; then
    echo 1
    return
  fi
  echo 0
}

DEBUG="$(is_debug "$1")"
DEBUG=1

function debug_msg {
  local msg="$1"
  if [ $DEBUG -eq 1 ] ; then
    printf "\n%s" "${msg}"
  fi
}

function publish_domain {
  local host_ip="$1"
  local domain="$2"

  /usr/bin/avahi-publish -a "${domain}" -R "${host_ip}" & disown
}

function read_cached_json {
  local cached_json=""

  if [ -f "${CACHE_FILE}" ] ; then
    cached_json="$(cat "${CACHE_FILE}")"
  fi

  if [ "" != "${cached_json}" ] ; then
    echo "${cached_json}"
  else
    echo '{"domains":[]}' | sudo tee "${CACHE_FILE}"
    return
  fi
}

function write_cached_json {
  local cached_json="$1"
  printf "%s" "${cached_json}" | sudo tee "${CACHE_FILE}" >/dev/null
}

function extract_cached_domains {
  local cached_json="$1"
  if [ "${cached_json}" == "" ] ; then
    cached_json="$(read_cached_json)"
  fi
  jq -r '.domains[]|.name' <<< "${cached_json}" \
    | sort \
    | tr "\n" ' '
}

# Dedups a space-separated list of domains
function dedup_domains {
  local domains="$1"
  tr ' ' "\n" <<< "${domains}" \
    | sort \
    | uniq \
    | tr "\n" ' '
}

function cache_has_domain {
  local domain="$1"
  local cached_domains="$2"
  local query

  query="$(printf '.domains[]|select(.name=="%s")' "${domain}")"
  result="$(echo "${cached_domains}" | jq -r "${query}")"
  test "" != "${result}"
}

function add_domain {
  local domain="$1"
  local cached_domains="$2"
  local query

  query="$(printf '.domains += [{"name":"%s", "last_seen": "%s"}]' "${domain}" "$(current_iso8601_datetime)")"
  jq "${query}" <<< "${cached_domains}"
}

function update_domain {
  local domain="$1"
  local cached_domains="$2"
  local query

  query="$(printf '.domains |= map(if .name == "%s" then .last_seen = "%s" else . end)' "${domain}" "$(current_iso8601_datetime)")"
  jq "${query}" <<< "${cached_domains}"
}

function current_iso8601_datetime {
  # Example: 2023-06-29T05:52:18Z where Z means UTC
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

function retrieve_routers_json {
  curl --silent "${TRAEFIK_ROUTERS_API_URL}"
}

function discover_published_domains {
  pgrep -a -x avahi-publish | awk '{print $4}' | tr "\n" ' '
}

function kill_published {
  pgrep avahi-publish | xargs kill -9
}

#
function extract_retrieved_domains {
  local routers_json="$1"

  jq -e '.[] | select(.rule|contains("Host(`"))|.rule' <<< "${routers_json}" \
      | tr '`' ' ' \
      | awk '{print$2}' \
      | sort \
      | uniq \
      | tr "\n" ' '
}

# Timing out domains last seen more than 24 hours ago.
function timeout_domains {
  local timeout_hours="$1"
  local cached_json="$2"
  local map
  local query
  local yesterday_seconds

  yesterday_seconds="$(( $(date +%s) - 60*60*timeout_hours ))"
  map="$(printf 'map(select((.last_seen | strptime("%s") | mktime)' "%Y-%m-%dT%H:%M:%SZ")"
  query="$(printf '.domains |= %s > %d))' "${map}" "${yesterday_seconds}")"
  jq "${query}" <<< "${cached_json}"
}

function main() {
  local space=' '
  local updated=0
  local routers_json
  local published_domains
  local cached_json
  local cached_domains
  local retrieved_domains
  local potential_domains
  local domain

  debug_msg "Use pgrep to discover the avahi-published .local domains from list of processes."
  published_domains="$(discover_published_domains)"
  debug_msg "published_domains: ${published_domains}"

  debug_msg "Read the cache file to find any domains that were previously there."
  cached_json="$(read_cached_json)"

  debug_msg "Time out domains last seen more than 24 hours ago."
  cached_json="$(timeout_domains 24 "${cached_json}")"

  debug_msg "Extract cached domains from cached json that was read from the cache file."
  cached_domains=$(extract_cached_domains "${cached_json}")

  debug_msg "Send an HTTP GET request to retrieve the routers JSON from Traefik API."
  routers_json="$(retrieve_routers_json)"
  if [ "${routers_json}" == "" ] ; then
    printf 'Warning: Unable to reach %s' "${TRAEFIK_ROUTERS_API_URL}" >&2
  fi

  debug_msg "Extract just the .local domains retrieved in Traefik into a space-separated string."
  retrieved_domains="$(extract_retrieved_domains "${routers_json}")"

  debug_msg "Combine Traefik-defined domains an previously cached domains into potential domains."
  potential_domains="${cached_domains} ${retrieved_domains}"

  debug_msg "Deduplicate domains after combining Traefik-defined and previously cached domains."
  potential_domains="$(dedup_domains "${potential_domains}")"

  debug_msg "Loop through the domains retrieved from Traefik to see if they have been published."
  for domain in $potential_domains; do
    debug_msg "Attempt to match a .local domain retrieved from Trafik to the list of domains currently published."
    debug_msg "$(printf 'Checking if %s is published_domains...' "${domain}")"
    if [[ "${space}${published_domains}${space}" =~ ${space}${domain}${space} ]] ; then
      [ $DEBUG -eq 1 ] && printf "already published"
      debug_msg "$(printf 'Updating .last_seen %s in cache file %s.' "${domain}", "${CACHE_FILE}")"
      debug_msg 'Since the domain is already published update JSON with last seen time.'
      if cache_has_domain "${domain}" "${cached_json}" ; then
        debug_msg 'Domain exists in cached JSON; update its last seen time.'
        cached_json="$(update_domain "${domain}" "${cached_json}")"
      else
        debug_msg 'Domain does not exist in cached JSON; add it.'
        cached_json="$(add_domain "${domain}" "${cached_json}")"
      fi
      debug_msg 'Now look at the next domain.'
      continue
    fi
    printf "Publishing %s\n" "${domain}"
    if ! publish_domain "${HOST_IP_ADDRESS}" "${domain}"; then
      printf 'Error: Unable to publish %s' "${domain}" >&2
    fi
    debug_msg "$(printf 'Adding %s to cache file %s.' "${domain}" "${CACHE_FILE}")"
    cached_json="$(add_domain "${domain}" "${cached_json}")"
    updated=1
    debug_msg "Write updated JSON to CACHE_FILE"
  done
  if [ "" != "${retrieved_domains}" ]; then
    debug_msg "Writing cache."
    write_cached_json "${cached_json}"
  fi
  if [ $DEBUG -eq 1 ]; then
    printf "\n"
  fi
  if [ $updated -eq 1 ]; then
    printf "\n"
  fi
}

main


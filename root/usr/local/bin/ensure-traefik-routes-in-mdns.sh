#!/usr/bin/env bash

function publish_domain {
  local host_ip="$1"
  local domain="$2"

  /usr/bin/avahi-publish -a "${domain}" -R "${host_ip}" &
}

function main() {
  local host_ip="$1"
  local published
  local defined
  local query
  local domain

  query='.[] | select(.rule|contains("Host(`"))|.rule'
  if ! curl https://traefik.local/api/http/routers > /tmp/traefik-routers.txt ; then
    echo "Warning: Unable to reach https://traefik.local/api" >&2
    # TODO Load cached values from JSON file
    #      Omit those last seen more than 24 hour ago
  fi
  published="$(ps -ax | grep "/usr/bin/avahi-publish" | grep -v grep | awk '{print $7}')"
  defined="$(< /tmp/traefik-routers.txt jq -r "${query}"|tr '`' ' '|awk '{print$2}'|sort|uniq)"
  for domain in $defined; do
    echo "Checking if ${domain} is published"
    # Loop through $defined and if not in $published then publish
    if [[ "${domain}" =~ $published ]] ; then
      # As it is published, look to the next one
      # Update JSON with last seen time
      continue
    fi
    echo "Publishing ${domain}"
    if ! publish_domain "${host_ip}" "${domain}"; then
      echo "Error: Unable to publish ${domain}" >&2
    fi
    # Update JSON with newly published domain and time
  done

}

# Get IP address from `ip addr`
main "192.168.1.110"
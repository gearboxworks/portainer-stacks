#!/usr/bin/env bash
source /tmp/provision/shared.sh

if ! [ -f acme.json ] ; then
  echo '{"default": {"Account": {"Email": "mike@gearbox.works"}}}' | tee acme.json >/dev/null
fi
sudo_chmod 600 acme.json
if ! [ -f traefik.json ] ; then
  echo '{"domains": []}' | sudo_tee traefik.json >/dev/null
fi
sudo_chmod 644 traefik-mdns.json
sudo_chmod 644 traefik.yaml
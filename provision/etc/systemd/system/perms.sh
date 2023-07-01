#!/usr/bin/env bash
source /tmp/provision/shared.sh

sudo_chmod 644 traefik-mdns.service
sudo_chmod 644 traefik-mdns.timer

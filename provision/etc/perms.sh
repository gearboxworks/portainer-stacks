#!/usr/bin/env bash
source /tmp/provision/shared.sh

# TODO See if we can reduce permissions on step
sudo_chmod 777 step
sudo_chmod 755 traefik

#!/usr/bin/env bash

sudo su
mkdir -p "/etc/traefik"
mkdir -p "/etc/traefik/certs"

mkdir -p "/etc/step"
chown 777 "/etc/step"
exit
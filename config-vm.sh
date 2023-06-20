#!/usr/bin/env bash

sudo su
mkdir -p "/etc/traefik"
mkdir -p "/etc/traefik/certs"

mkdir -p "/etc/smallstep"
chown 777 "/etc/smallstep"
exit
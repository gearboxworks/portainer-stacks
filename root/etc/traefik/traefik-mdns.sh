#!/usr/bin/env bash

curl https://traefik.local/api/http/routers > ~/routers.txt
cat ~/routers.txt | jq -r '.[].rule | select(.|contains("Host(`"))'| tr '`' ' '|awk '{print$2}'|sort|uniq

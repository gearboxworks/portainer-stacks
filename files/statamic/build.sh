#!/usr/bin/env sh

docker rmi "$(docker images | grep statamic | awk '{print $3}')"

docker build -t statamic:latest -f Dockerfile.statamic .
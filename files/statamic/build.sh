#!/usr/bin/env sh

image="$(docker images --filter "reference=statamic:latest" -q)"
for c in $(docker ps --filter "ancestor=${image}" -q) ; do
  docker stop "${c}" && docker rm "${c}"
done

#Maybe I don't need this next line?
#docker rmi "$(docker images | grep statamic | awk '{print $3}')"

docker build -t statamic:latest -f Dockerfile.statamic .

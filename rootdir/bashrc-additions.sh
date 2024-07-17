## Append these to the end of `.bashrc

#### Mike's Additions

function container_exists() {
  local container="$1"
  docker container \
    inspect "${container}" \
    >/dev/null 2>&1
}

alias docker-ps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Ports}}\t{{.Names}}"'

if container_exists portainer ; then
   docker start portainer
else
  docker run \
    --detach \
    --publish 80:8000 \
    --publish 443:9443 \
    --name portainer \
    --restart=always \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume portainer_data:/data \
    portainer/portainer-ce:2.16.2
fi

source /home/mikeschinkel/.config/bash-macros/bash-macros.sh

#!/usr/bin/env bash

function chr() {
    printf "\\$(printf '%03o' $((97 + $1)))" # ASCII value of 'a' is 97
}
function download() {
  local url="https://golang.cafe/x/skill/autocomplete?k=$1"

  http \
    --pretty=none \
    --print=b \
    GET "${url}" \
    | jq -r 'map("\(.),") | .[]'
}

echo "[" > skills.json

for ((i=0; i<26; i++)); do
    first=$(chr $i)
    # Inner loop for the second letter (a to z)
    for ((j=0; j<26; j++)); do
        second=$(chr $j)
        key="${first}${second}"
        echo "Download skills for '${key}'"
        response="$(download "${key}")"
        if [ "" != "${response}" ]; then
          printf "%s" "${response}" >> skills.json
        fi
    done
done

echo '{"name":""}' >> skills.json
echo "]" >> skills.json

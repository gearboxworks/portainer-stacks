#!/usr/bin/env bash

SECONDS=0
wp search-replace "$1" "$2" --all-tables --precise --allow-root
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."


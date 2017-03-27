#!/bin/bash


IFS=',' read -a STRINGS <<< "$@"
for s in "${STRINGS[@]}"; do
  echo "s=>$s"
done

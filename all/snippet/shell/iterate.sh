#!/bin/bash

declare -a ARRAY=(
  "abc"
  "123"
  "foo"
)

for i in "${ARRAY[@]}"; do
  echo "i=>$i"
done

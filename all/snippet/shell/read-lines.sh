#!/bin/bash

while IFS='' read -r line || [[ -n "$line" ]]; do
  echo "line=>$line"
done < "$1"

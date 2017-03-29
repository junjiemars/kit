#!/bin/bash

if [ 0 -eq "${#@}" ]; then
  echo "$0 [error]: invalid input"
  exit 1
fi

SC_IN="$@"
SC_TXT=

if [ "@" = "${SC_IN:0:1}" ]; then
  SC_IN="${SC_IN:1}"
  if [ -z "${SC_IN}" -o ! -f "${SC_IN}" ]; then
    echo "$0 [error]: ${SC_IN} no found"
    exit 1
  fi
  SC_IN="`cat ${SC_IN}`"
else
  SC_IN="${SC_IN}"
fi

IFS=',' read -a SC_TXT <<< "$SC_IN"
echo -e "raw=>\n${SC_TXT[@]}\n=========="
echo -e "count=> (${#SC_TXT[@]})"

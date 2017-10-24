#!/bin/bash
#------------------------------------------------
# target: platform
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`

on_windows_nt() {
  case "$PLATFORM" in
    MSYS_NT*|MINGW*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if `on_windows_nt`; then
  if [ -d "/d/" ]; then
    PREFIX="${PREFIX:-/d/opt}"
  else
    PREFIX="${PREFIX:-/c/opt}"
  fi
else
  PREFIX="${PREFIX:-/opt}"
fi

SED_OPT_I="-i''"
[ "Darwin" = "$os" ] && SED_OPT_I="-i ''"

RUN_DIR="${RUN_DIR:-${PREFIX}/run}"
OPEN_DIR="${OPEN_DIR:-${PREFIX}/open}"
SOCKS="${SOCKS}"

export PREFIX
export RUN_DIR
export OPEN_DIR
export SOCKS
export SED_OPT_I
export -f on_windows_nt


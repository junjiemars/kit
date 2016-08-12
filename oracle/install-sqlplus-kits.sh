#!/bin/bash
#------------------------------------------------
# target: SQL*Plus Kits 
# author: junjiemars@gmail.com
#------------------------------------------------

HAS_ALL=${HAS_ALL:-'0'}
BIN_DIR=

check_env() {
  [ 0 -ne `sqlplus -v &>/dev/null; echo $?` ] && return 1
  [ 0 -ne `sqlplus.sh -v &>/dev/null; echo $?` ] && return 1
    
  [ 0 -eq "${HAS_ALL}" ] && return 0

  [ 0 -ne `imp HELP=YES &>/dev/null; echo $?` ] && return 1
  [ 0 -ne `imp.sh HELP=YES &>/dev/null; echo $?` ] && return 1

  return 0
}

bin_dir() {
  local pwd="$1"
  local name="$2"

  BIN_DIR=''
  if [ 0 -ne `ls "${name}" &>/dev/null; echo $?` ]; then
    return 1
  fi

  local d=`find "${pwd}" -type d -name "${name}" -execdir stat {} + \
              | grep 'Change:' | cut -d' ' -f2,3 | sort -r | head -n1`
  [ -z `echo ${d}` ] && return 1
  local t=`echo "${d}" | sed -e 's/\.[0-9]*//' `
  local r=`find "${pwd}" -type d -name "${name}" -newerct "${t}" 2>/dev/null`
  [ -z `` ] && return 1

  BIN_DIR='?'
  return 0
}

check_bag() {
  return 0
}

install_client_kit() {
  [ 0 -eq `` ] && printf "%s\n" "sqlplus kits exists, good."
  
  return 0 
}

install_server_kit() {
  return 0  
}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help ]\n"
  echo -e "A tiny-handy install for sqlplus client/server kits.\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage\n"
  echo -e "Commands:"
  echo -e "\t-c | --install-client-kit\t\tinstall sqlplus's client kit"
  echo -e "\t-s | --install-server-kit\t\tinstall sqlplus's server kit"
}

case ".$@" in
  .-c|.--install-client-kit) install_client_kit ;;
  .-s|.--install-server-kit) install_server_kit ;;
  .-h|.--help) usage ;;
  .*) usage ;;
esac

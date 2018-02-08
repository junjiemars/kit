#!/bin/bash
#------------------------------------------------
# target : get default code page
# author : junjiemars@gmail.com
#------------------------------------------------

verbose=no

for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    -v|--verbose)               verbose=yes                ;;
    *)
      exit 1
    ;;
  esac
done

code_page=("`powershell [System.Text.Encoding]::Default`")

if [ -z "$code_page" ]; then
  exit 1
fi

if [ yes = $verbose ]; then
  echo "${code_page[@]}"
else
  echo "${code_page[@]}" | grep "^CodePage\ *:.*" | cut -d':' -f2 
fi
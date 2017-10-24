#!/bin/bash
#------------------------------------------------
# target: install
# author: junjiemars@gmail.com
#------------------------------------------------

append_paths() {
  local f_paths="$HOME/.bash_paths"
	local name="PATH"
	local val="\${PATH:+\$PATH:}$1"
	local flag="$2"
	local var="${name}=\"${val}\""
  if `grep "^${name}=\".*${flag}.*\"" "${f_paths}" &>/dev/null`; then
    sed $sed_i_0 "s#^${name}=\".*${flag}\"#${var}#g" "${f_paths}"
	else
    echo -e "${var}" >> "${f_paths}"
  fi
  . "${f_paths}"
}

append_vars() {
  local f_vars="$HOME/.bash_vars"
  local name="$1"
  local val="$2"
  local var="export ${name}='${val}'"
  if `grep "^export ${name}='.*'" "${f_vars}" &>/dev/null`; then
    sed $sed_i_0 "s#^export ${name}='.*'#${var}#g" "${f_vars}"
  else
    echo -e "${var}" >> "${f_vars}"
  fi
  . "${f_vars}"
}

chmod_file() {
	local f="$1"
	local o="$2"

	if [ -n "$f" ] && [ -n "$o" ] && [ -f "$f" ]; then
		chmod "$o" "$f"
	else
		return 1
	fi
}

export -f append_paths
export -f append_vars
export -f chmod_file

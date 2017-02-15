#!/bin/bash
#------------------------------------------------
# target: bash env setup script	
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`
GITHUB_H=${GITHUB_H:-"https://raw.githubusercontent.com/junjiemars/kit/master"}
curl='curl -sL '
declare -a BASH_S=(\
  '.bash_aliases' \
  '.bash_vars' \
  '.bash_paths' \
  '.bashrc' \
  '.profile' \
  '.bash_profile' \
  '.bash_logout' \
  '.vimrc' \
  '_vimrc' \
  )

save_as() {
  local f="$HOME/$1"
	local ori=$f.ori
  case "${PLATFORM}" in
    MSYS_NT*) 
      local find='/usr/bin/find' 
      local sort='/usr/bin/sort'
      ;;
    *) 
      local find='find' 
      local sort='sort'
      ;;
  esac

  if [ -f ${f} ]; then
		[ -f ${ori} ] || cp $f $ori
    local l=`$find $HOME -maxdepth 1 -mindepth 1 -type f -name "$1.b?" \
            |$sort -r|head -n1`
    if [ "_${l}" == "_" ]; then
      local n=0
    else
      local c="${l:$(( ${#l}-1 )):1}"
      local n=$(( ${c}+1 ))
      if [[ ${n} -gt 2 ]]; then
        let n=0
        [ -f "${f}.b1" ] && mv "${f}.b1" "${f}.b2"
        [ -f "${f}.b0" ] && mv "${f}.b0" "${f}.b1"
      fi
    fi
    cp "${f}" "${f}.b${n}"
  fi
}

set_vim_path_var() {
  local f=$1
  shift
  local inc_lns=("${@}")
  local inc_ln="${#inc_lns[@]}"

  echo -e "\n\" cc include path :checkpath" >> $f
  for i in "${inc_lns[@]}"; do
		local ln=$(echo "$i" | sed 's_ _\\\\\\ _g')
    echo "set path+=${ln}" >> $f
  done
}

check_linux_cc_include() {
	local inc_list=$1
	local vimrc=$2
  if `type -p cc &>/dev/null`; then
    local cc_out="`echo '' | cc -v -E 2>&1 >/dev/null - \
									| awk '/#include <...> search starts here:/,/End of search list./'`"
    [ -n "$cc_out" ] || return 1

		local inc_lns=()
		IFS=$'\n'
		for l in `echo "$cc_out"`; do
			inc_lns+=($(echo "$l" | sed 's/^ //'))
		done
		unset IFS

		cat /dev/null > "$inc_list"
		local inc_ln="${#inc_lns[@]}"
		if [[ 2 -lt "$inc_ln" ]]; then
			local inc_paths=("${inc_lns[@]:1:$(( inc_ln-2  ))}")
			echo "${inc_paths[@]}" >> "$inc_list"
			set_vim_path_var "${vimrc}" "${inc_paths[@]}"
    fi
  fi
}

check_win_cc_include() {
	local inc_list="$1"
  local vimrc="$2"
  local inc_bat="$3"

	local vstools="`env|grep 'VS[0-9][0-9]*COMNTOOLS'|sed 's#^VS[0-9]*COMNTOOLS=\(.*\)$#\1#g'`"
	[ -n "$vstools" ] || return 0
	[ -d "$vstools" ] || return 1

  vstools="`( cd "$vstools/../../VC" && pwd )`"
	vstools="`echo "$vstools" | sed -e 's#^\/\([a-z]\)#\u\1:#'`"

  cat <<END > "$inc_bat"
@echo off
set wpwd=%cd%
cd /d "$vstools"
if "%1" == "" goto x86
if /i "%2" == "x86_64" goto x86_64

:x86
call vcvarsall.bat
set CC=cl
set AS=ml
goto :echo_inc

:x86_64
call vsvarsall.bat x86_amd64
set CC=cl
set AS=ml64
goto :echo_inc

:echo_inc
cd /d %wpwd%
echo "%INCLUDE%" 
END

	[ -f "$inc_bat" ] || return 1
	chmod u+x "$inc_bat"

 	local include=$($inc_bat) 
	[ -n "$include" ] || return 1

	cat /dev/null > "$inc_list"
 	include=$(echo $include | sed 's#\"##g')
 	local inc_lns=()
 	IFS=$';'
 	for i in `echo "${include}"`; do
		local ln=$(echo "\\${i}"|sed -e 's#^\\\([a-zA-Z]\):\\#\\\l\1\\#' -e 's#\\#\/#g')
		echo "'$ln'" >> "$inc_list"
		inc_lns+=( "$ln" )
 	done
 	unset IFS

 	set_vim_path_var "${vimrc}" "${inc_lns[@]}"
}


BEGIN=`date +%s`
echo "setup $PLATFORM bash env ..."

for i in "${BASH_S[@]}"; do
  `save_as "$i"`
done

${curl} ${GITHUB_H}/ul/.bash_aliases -o $HOME/.bash_aliases
${curl} ${GITHUB_H}/ul/.bash_vars -o $HOME/.bash_vars
${curl} ${GITHUB_H}/ul/.bash_paths -o $HOME/.bash_paths
${curl} ${GITHUB_H}/ul/.bash_profile -o $HOME/.bash_profile

case ${PLATFORM} in
  MSYS_NT*)
    ${curl} ${GITHUB_H}/win/.bashrc -o $HOME/.bashrc
    ${curl} ${GITHUB_H}/ul/.vimrc -o $HOME/_vimrc && \
      cp $HOME/_vimrc $HOME/.vimrc
    ;;
  *)
		${curl} ${GITHUB_H}/ul/.bashrc -o $HOME/.bash_init
		sed -i'' -e '/test -f \$HOME\/\.bash_init/d' $HOME/.bashrc
		if `tail -n1 $HOME/.bashrc | grep 'export\ * PATH' &>/dev/null`; then
			sed -i'' -e '$d' $HOME/.bashrc
		fi
		cat << END >> $HOME/.bashrc
test -f \${HOME%/}/.bash_init && . \${HOME%/}/.bash_init
export PATH
END
    ${curl} ${GITHUB_H}/ul/.bash_logout -o $HOME/.bash_logout
    ${curl} ${GITHUB_H}/ul/.vimrc -o $HOME/.vimrc
    ;;
esac

. $HOME/.bashrc

case ${PLATFORM} in
  Linux)
    check_linux_cc_include $HOME/.cc-inc.list $HOME/.vimrc
    ;;
  MSYS_NT*)
    check_win_cc_include $HOME/.cc-inc.list $HOME/.vimrc $HOME/.vs-inc.bat
    ;;
  *)
    ;;
esac

END=`date +%s`
echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."


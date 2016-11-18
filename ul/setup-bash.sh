#!/bin/bash
#------------------------------------------------
# target: bash env setup script	
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`
GITHUB_H=${GITHUB_H:-"https://raw.githubusercontent.com/junjiemars/kit/master"}
curl='curl -s '
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

  echo -e "\n\" cc include path" >> $f
  for i in "${inc_lns[@]}"; do
    echo "set path+=${i}" >> $f
  done
}

check_linux_cc_include() {
	local vimrc=$1
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
		local inc_ln="${#inc_lns[@]}"
		if [[ 2 -lt "$inc_ln" ]]; then
			local inc_paths=("${inc_lns[@]:1:$(( inc_ln-2  ))}")
			set_vim_path_var "${vimrc}" "${inc_paths[@]}"
    fi
  fi
}

to_posix_path() {
	echo "\\$1" | \
	  sed \
      -e 's#^\\\([a-zA-Z]\):\\#\\\l\1\\#' \
      -e 's#\\#\/#g' \
      -e 's# #\\\\\\ #g'
}

check_win_cc_include() {
  local vimrc="$1"
  local inc_bat="$2"

  [ -f "$inc_bat" ] || return 1

  local include=$($inc_bat "`env|grep 'VS[0-9][0-9]*COMNTOOLS'|sed 's#^VS[0-9]*COMNTOOLS=\(.*\)$#\1#g'`")
  [ -n "$include" ] || return 1

  include=$(echo $include | sed 's#\"##g')
  local inc_lns=()
  IFS=$';'
  for l in `echo "$include"`; do
		inc_lns+=(`to_posix_path $(echo "$l" | sed 's/^ //')`)
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
    ${curl} ${GITHUB_H}/win/vs-inc.bat -o $HOME/.vs-inc.bat
    ;;
  *)
		${curl} ${GITHUB_H}/ul/.bashrc -o $HOME/.bash_init
		sed -i'' -e '/test -f \$HOME\/\.bash_init/d' $HOME/.bashrc
		if `tail -n1 $HOME/.bashrc | grep 'export\ * PATH' &>/dev/null`; then
			sed -i'' -e '$d' $HOME/.bashrc
		fi
		cat << END >> $HOME/.bashrc
test -f \$HOME/.bash_init && . \$HOME/.bash_init
export PATH
END
    ${curl} ${GITHUB_H}/ul/.bash_logout -o $HOME/.bash_logout
    ${curl} ${GITHUB_H}/ul/.vimrc -o $HOME/.vimrc
    ;;
esac

. $HOME/.bashrc

case ${PLATFORM} in
  Linux)
    check_linux_cc_include $HOME/.vimrc
    ;;
  MSYS_NT*)
    check_win_cc_include $HOME/.vimrc $HOME/.vs-inc.bat
    ;;
  *)
    ;;
esac

END=`date +%s`
echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."


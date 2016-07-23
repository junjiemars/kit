#!/bin/bash
# usage: bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)
# if ur `sh' is not `dash' use `sh' instead.

GITHUB_H='https://raw.githubusercontent.com/junjiemars/kit/master'
PLATFORM=`uname -s 2>/dev/null`
curl='curl -s '
declare -a BASH_S=(\
  '.bash_aliases' \
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
  if [ -f ${f} ]; then
    local l=`find $HOME -maxdepth 1 -mindepth 1 -type f -name "$1.b?" \
            |sort -r|head -n1`
    if [ "_${l}" == "_" ]; then
      local n=0
    else
      local c="${l:$(( ${#l}-1 )):1}"
      local n=$(( ${c}+1 ))
      if [[ ${n} -gt 2 ]]; then
        let n=0
      fi
    fi
    cp "${f}" "${f}.b${n}"
  fi
}

set_vim_paths() {
  if [[ 0 -eq `type -p cc >/dev/null; echo $?` ]]; then
    cc_out="`echo '' | cc -v -E 2>&1 >/dev/null - \
            | awk '/#include <...> search starts here:/,/End of search list./'`"
    if [ -n "$cc_out" ]; then
      inc_lns=()
      IFS=$'\n'
      for l in `echo -e "$cc_out"`; do
        inc_lns+=($(echo -e "$l" | sed 's/^ //'))
      done
      unset IFS
      inc_ln="${#inc_lns[@]}"
      if [[ 2 -lt "$inc_ln" ]]; then
        inc_paths=("${inc_lns[@]:1:$(( inc_ln-2  ))}")
        echo -e "${#inc_paths[@]}"
        echo -e "\n\" cc include path" >> $1
        for i in "${inc_paths[@]}"; do
          echo -e "set path+=${i}" >> $1
        done
      fi
    fi
  fi
}

BEGIN=`date +%s`
echo "setup $PLATFORM bash env ..."

for i in ${BASH_S[@]}; do
  `save_as $i`
done

${curl} ${GITHUB_H}/ul/.bash_aliases -o $HOME/.bash_aliases
${curl} ${GITHUB_H}/ul/.bash_profile -o $HOME/.bash_profile

case ${PLATFORM} in
  MSYS_NT*)
    ${curl} ${GITHUB_H}/win/.bash_paths -o $HOME/.bash_paths
    ${curl} ${GITHUB_H}/win/.bashrc -o $HOME/.bashrc
    ${curl} ${GITHUB_H}/ul/.vimrc -o $HOME/_vimrc
    ;;
  *)
    ${curl} ${GITHUB_H}/ul/.bash_logout -o $HOME/.bash_logout
    ${curl} ${GITHUB_H}/ul/.vimrc -o $HOME/.vimrc
    ;;
esac

. $HOME/.bashrc

case ${PLATFORM} in
  Linux)
    set_vim_paths $HOME/.vimrc
    ;;
  *)
    ;;
esac

END=`date +%s`
echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."


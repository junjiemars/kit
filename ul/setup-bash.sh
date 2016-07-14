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
    local l=`find $HOME -type f -maxdepth 1 -mindepth 1 -name "$1.b?" \
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

BEGIN=`date +%s`
echo "setup $PLATFORM bash env ..."

for i in ${BASH_S[@]}; do
  `save_as $i`
done

${curl} ${GITHUB_H}/ul/.bash_aliases > $HOME/.bash_aliases
${curl} ${GITHUB_H}/ul/.bash_profile > $HOME/.bash_profile

case ${PLATFORM} in
  MSYS_NT*)
    ${curl} ${GITHUB_H}/win/.bash_paths > $HOME/.bash_paths
    ${curl} ${GITHUB_H}/win/.bashrc > $HOME/.bashrc
    ${curl} ${GITHUB_H}/ul/.vimrc > $HOME/_vimrc
    ;;
  *)
    ${curl} ${GITHUB_H}/ul/.bash_logout > $HOME/.bash_logout
    ${curl} ${GITHUB_H}/ul/.vimrc > $HOME/.vimrc
    ;;
esac

END=`date +%s`
echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."

. $HOME/.bashrc

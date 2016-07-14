#!/bin/bash
# usage: bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)
# if ur `sh' is not dash use `sh' indeed

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
  test -f $HOME/$1 && cp $HOME/$1 $HOME/$1.b0
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

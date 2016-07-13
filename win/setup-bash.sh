#!/bin/bash
# usage: sh <(curl https://raw.githubusercontent.com/junjiemars/kit/master/win/setup-bash.sh)


GITHUB_H='https://raw.githubusercontent.com/junjiemars/kit/master'
curl='curl -s '
declare -a BASH_S=(\
	'.bash_aliases' \
	'.bash_paths' \
	'.bashrc' \
	'.bash_profile' \
	'_vimrc')

save_as() {
  test -f $HOME/$1 && mv ~/$1 $HOME/$1.b0
}

BEGIN=`date +%s`
echo "setup `uname -s` shell env on Windows ..."

for i in ${BASH_S[@]}; do
	`save_as $i`
done

${curl} ${GITHUB_H}/ul/.bash_aliases > $HOME/.bash_aliases
${curl} ${GITHUB_H}/win/.bash_paths > $HOME/.bash_paths
${curl} ${GITHUB_H}/win/.bashrc > $HOME/.bashrc
${curl} ${GITHUB_H}/win/.bash_profile > $HOME/.bash_profile
${curl} ${GITHUB_H}/win/_vimrc > $HOME/_vimrc

END=`date +%s`

echo 
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."

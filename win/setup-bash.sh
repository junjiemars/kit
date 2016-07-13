#!/bin/bash

echo "begin setup `uname -s` shell env on Windows ..."

GITHUB_H='https://raw.githubusercontent.com/junjiemars/kit/master'

save_as() {
  test -f ~/$1 && mv ~/$1 ~/$1.b0
}

`save_as '.bash_aliases'` && curl -O ${GITHUB_H}/ul/.bash_aliases
`save_as '.bash_paths'` && curl -O ${GITHUB_H}/win/.bash_paths
`save_as '.bashrc'` && curl -O ${GITHUB_H}/win/.bashrc
`save_as '.bash_profile'` && curl -O ${GITHUB_H}/win/.bash_profile
`save_as '_vimrc'` && curl -O ${GITHUB_H}/win/_vimrc

echo "setup `uname -s` shell env on Windows successed"

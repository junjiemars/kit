#!/bin/bash

echo "begin setup `uname -s` shell env on Windows ..."

GITHUB_H='https://raw.githubusercontent.com/junjiemars/kit/master'

save_as() {
  test -f $HOME/$1 && mv ~/$1 $HOME/$1.b0
}

`save_as '.bash_aliases'` && \
  curl ${GITHUB_H}/ul/.bash_aliases > $HOME/.bash_aliases

`save_as '.bash_paths'` && \
  curl ${GITHUB_H}/win/.bash_paths > $HOME/.bash_paths

`save_as '.bashrc'` && \
  curl -O ${GITHUB_H}/win/.bashrc > $HOME/.bashrc

`save_as '.bash_profile'` && \
  curl -O ${GITHUB_H}/win/.bash_profile > $HOME/.bash_profile

`save_as '_vimrc'` && \
  curl -O ${GITHUB_H}/win/_vimrc > $HOME/_vimrc

echo "setup `uname -s` shell env on Windows successed"

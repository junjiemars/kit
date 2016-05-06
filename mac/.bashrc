# PS1="\h:\W \u\$ "
PS1="\u@\h:\w\$ "

## lang
export LANG=en_US.UTF-8

## macports
PATH=$PATH:/opt/local/bin:/opt/local/sbin:

HOME_BIN=~/.bin
OPT_BIN=/opt/bin
PATH=$PATH:$HOME_BIN:$OPT_BIN

## java
export JDK_ROOT=$(/usr/libexec/java_home)
export GRADLE_HOME=$OPT_BIN/gradle
PATH=$PATH:$JDK_HOME:$GRADLE_HOME/bin

## postgre
export PGUSER=books
DB_PATH=/opt/local/lib/postgresql94/bin
PATH=$PATH:$DB_PATH

## rebar
PATH=$PATH:$OPT_BIN/rebar

## racket
RACKET_HOME='/Applications/Racket v6.3'
PATH=$PATH:"$RACKET_HOME/bin"

## flake8
PATH=$PATH:$HOME/.local/bin

export PATH

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

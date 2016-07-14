PS1="\u@\h:\w\$ "

## lang
export LANG=en_US.UTF-8

## macports
PATH=$PATH:/opt/local/bin:/opt/local/sbin:

OPT_RUN=/opt/run
PATH=$PATH:$OPT_RUN:$OPT_RUN/bin:$OPT_RUN/sbin

## java
export JDK_ROOT=$(/usr/libexec/java_home)
PATH=$PATH:$JDK_HOME

## postgre
export PGUSER=books
DB_PATH=/opt/local/lib/postgresql94/bin
PATH=$PATH:$DB_PATH

## racket
RACKET_HOME='/Applications/Racket v6.5'
PATH=$PATH:"$RACKET_HOME/bin"

export PATH

if [ -r ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

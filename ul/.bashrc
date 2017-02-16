# minimal .bashrc, can be on Docker or EC2

export HOME=${HOME%/}

case ".$PS1" in
	.|.\\s*|.[\\*)
		PS1="\u@\h:\w\$ "
		;;
	*)
		;;
esac

#PREFIX=/opt
#JAVA_HOME=
#TMOUT=3000 # seconds
#readonly TMOUT
#export TMOUT

test -f $HOME/.bash_vars && . $HOME/.bash_vars

test -f $HOME/.bash_paths && . $HOME/.bash_paths
export PATH

test -f $HOME/.bash_aliases && . $HOME/.bash_aliases 

#export LANG=en_US.UTF-8

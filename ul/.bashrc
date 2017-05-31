# minimal .bashrc, can be on Docker or EC2

export HOME=${HOME%/}

case ".$PS1" in
	.|.\\s*|.[\\*|.\\h:*)
		PS1="\u@\h:\w\$ "
		;;
	*)
		;;
esac

#PREFIX=/opt

# fix set locale failed
# sudo localedef -i en_US -f UTF-8 en_US.UTF-8


test -f $HOME/.bash_vars && . $HOME/.bash_vars

test -f $HOME/.bash_paths && . $HOME/.bash_paths
export PATH

test -f $HOME/.bash_aliases && . $HOME/.bash_aliases 

# customize
#---------- 
#export LANG=en_US.UTF-8
#TMOUT=3000 # seconds
#readonly TMOUT
#export TMOUT


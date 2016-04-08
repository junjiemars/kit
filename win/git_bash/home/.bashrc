alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'
alias ll='ls -alh'

LOCAL_BIN="/c/bin"
export PS1="\[\033]0;$TITLEPREFIX:${PWD//[^[:ascii:]]/?}\007\]\n\[\033[32m\]\u@\h \[\033[35m\]$MSYSTEM \[\033[33m\]\w\[\033[36m\]\[\033[0m\]\n$"
PATH="$PATH:$LOCAL_BIN:$LOCAL_BIN/emacs-24.4/bin"
export PATH

alias clojure="java -cp $LOCAL_BIN/clojure-1.6.0.jar clojure.main"

SSID=$(netsh wlan show interfaces|grep -m1 SSID|cut -d':' -f2|tr -ds ' ' '') 
if [[ 'H' == ${SSID} ]]; then
	IPV6_TEST='ipv6-test.com'
	IPV4_TUNNEL='<tunnelling>'
	$(ping -6 -n 3 ${IPV6_TEST} &> /dev/null)
	PING6=$?
	if [[ ${PING6} -ne 0 ]]; then
	  curl -v ${IPV4_TUNNEL} 
	fi
fi

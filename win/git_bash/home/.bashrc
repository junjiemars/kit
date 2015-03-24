alias ll="ls -aFlh"
alias ..1="cd ../"
alias ..2="cd ../../"
alias ..3="cd ../../../"
alias ..4="cd ../../../../"
alias view="vi -R"
alias emacs="/d/bin/emacs-24.3/bin/emacs.exe -nw"

## ssh-agent
##`ps aux|grep ssh-agent`
##SSH_AGENT_EXISTS=$?
##if [ -z "$SSH_AUTH_SOCK" ]; then
##	eval "$(ssh-agent -s)"
##	ssh-add "$HOME/.ssh/id_rsa"
##fi

agent_env="$HOME/.ssh/agent.env"
agent_is_running() {
	if [ "$SSH_AUTH_SOCK" ]; then
		ssh-add -l > /dev/null 2>&1 || [ $? -eq 1 ]
	else
		false
	fi
}

agent_has_keys() {
	ssh-add -l > /dev/null 2>&1
}

agent_load_env() {
	. "$agent_env" > /dev/null
}

agent_start() {
	(umask 077; ssh-agent > "$agent_env")
	. "$agent_env" > /dev/null
}

if ! agent_is_running; then
	agent_load_env
fi

if ! agent_is_running; then
	agent_start
	ssh-add
elif ! agent_has_keys; then
	ssh-add
fi

unset agent_env

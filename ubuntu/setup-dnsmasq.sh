#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: setup dnsmasq
# 
#------------------------------------------------

GITHUB_H="https://raw.githubusercontent.com/junjiemars/kit/master"
DNSMASQ_C="/etc/dnsmasq.conf"
DNS_PORT=${DNS_PORT:-5533}

check_dnsmasq() {
	if `type -p dnsmasq &>/dev/null`; then
		return 0
	else
		return 1
	fi
}

install_dnsmasq() {
	if `check_dnsmasq`; then
		return 0
	fi

	if `sudo apt-get -y update` -a `sudo apt-get -y install dnsmasq`; then
		return 0
	else
		return 1
	fi
}

setup_dns() {
	if [ ! -f "$DNSMASQ_C.ori" ]; then
		sudo cp $DNSMASQ_C $DNSMASQ_C.ori
	else
		sudo cp $DNSMASQ_C $DNSMASQ_C.b0
	fi

cat << END > /tmp/dnsmasq.conf
domain-needed
bogus-priv
#no-resolv
#no-poll

server=8.8.4.4
server=74.82.42.42

#listen-address=0.0.0.0
port=$DNS_PORT

#log-queries
END

sudo cp /tmp/dnsmasq.conf $DNSMASQ_C
}

op_dnsmasq() {
	if `check_dnsmasq`; then
		sudo service dnsmasq $1
	fi
}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "A dnsmasq setup on ubuntu.\n"
  echo -e "Commands:"
  echo -e "\tdns\t\tSetup a DNS server"
  echo -e "\trestart\t\tRestart the DNS server"
  echo -e "\tstop\t\tStop the DNS server"
  echo -e "\tstatus\t\tShow status of the DNS server"
}

case ".$@" in
  .dns)
		install_dnsmasq
    setup_dns
		op_dnsmasq restart
    ;;
  .restart|.stop|.status)
		op_dnsmasq $@
		;;
  .-h|.--help)
    usage
    ;;
  .*) usage
    ;;
esac


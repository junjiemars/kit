#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: setup dnsmasq
# 
#------------------------------------------------

GITHUB_H="https://raw.githubusercontent.com/junjiemars/kit/master"
DNSMASQ_C="/etc/dnsmasq.conf"
RESOLV_C="/etc/resolv.conf"
DNS_PORT=${DNS_PORT:-5533}

check_dnsmasq() {
	if `type -p dnsmasq &>/dev/null`; then
		return 0
	else
		return 1
	fi
}

check_ip() {
	local ipv4=`ifconfig eth0 |grep 'inet addr'|cut -d: -f2|cut -d' ' -f1`
	echo $ipv4
}

is_ec2() {
	local ipv4=`echo $(check_ip) | tr '.' '-'`
	if `hostname | grep "ip-$ipv4" &>/dev/null`; then
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

	if [ ! -f "$RESOLV_C.ori" ]; then
		sudo cp $RESOLV_C $RESOLV_C.ori
		sudo echo "nameserver 8.8.4.4" >> $RESOLV_C
	fi

	if `is_ec2`; then
		local ec2_local_dns="server=172.31.0.2#53"
	fi
	

cat << END > /tmp/dnsmasq.conf
domain-needed
bogus-priv
no-resolv
no-poll

$ec2_local_dns
server=8.8.4.4
server=74.82.42.42

rev-server=127.0.0.1/8,127.0.0.1#$DNS_PORT

#interface=eth0
#listen-address=$ipv4
port=$DNS_PORT

no-dhcp-interface=

log-queries
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


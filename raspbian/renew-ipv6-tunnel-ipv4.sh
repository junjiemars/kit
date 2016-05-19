#!/bin/bash
IPV6_TEST=${IPV6_TEST:-"ipv6-test.com"}
IPV6_KEY='<ipv6-key>'
IPV6_SN='<ipv6-sn>'
IPV6_TUNNEL=${IPV6_TUNNEL:-"<ipv6-tunnel>"}
IPV6_STAT=${IPV6_TUNNEL_STAT:-/tmp/ipv6.stat}
IPV4_ISP=${IPV4_ISP:-"https://api.ipify.org?format=json"}
IP_CHECK=${IP_CHECK:-"http://checkip.dns.he.net"}
IPV4_FILE=${IPV4_FILE:-/tmp/ipv4.addr}
IPV6_FILE=${IPV6_FILE:-/tmp/ipv6.addr}
IPV4_ADDR=
IPV6_ADDR=
HOST_NAME=${HOST_NAME:-"<host-name>"}
HOST_PASS=${HOST_PASS:-"<host-passwd>"}
DNS_RENEW=${DNS_RENEW:-"http://dyn.dns.he.net/nic/update"}
SSH_LOGGER=${SSH_LOGGER:-"<ssh-logger>"}
SLEEP_S=10s

DEBUG=${DEBUG:-0}

get_ip_addr() {
    local _addr=$1
    if [ -f ${_addr} ]; then
        echo `cat ${_addr} \
            | tr '\n' '|' \
            | grep -o '<body>|.*</body>' \
            | sed -e 's/<body>|Your IP address is ://g' \
                  -e 's/<\/body>//g'`
    fi
}

post_ip_addr() {
    local _ip=$1
    local _v=$2
    echo `curl -s${_v} ${DNS_RENEW} \
        -d "hostname=${HOST_NAME}" \
        -d "password=${HOST_PASS}" \
        -d "myip=${_ip}"`
}

good_ipv6() {
    local _stat=$1
    if [ -f ${_stat} ]; then
        echo `cat ${_stat} | grep -o '\(nochg\|good\)' 2>&1 >/dev/null; echo $?`
    else
        echo 1
    fi
}

ping6_check() {
    local _v6=$1
    ping6 -q -c3 ${_v6} >/dev/null 2>&1; echo $? 
}

ipv4_rot() {
    local _d4=`dig ${HOST_NAME} +short`
    local _r4=`curl -s4 ${IPV4_ISP} | sed 's/\({"ip":"\|"}\)//g'`
    [ ".${_d4}" = ".${_r4}" ]; echo $?
}

if [[ 0 -eq ${DEBUG} ]]; then
    if [ "0" != `ping6_check ${IPV6_TEST}` ] || [ "0" != `ipv4_rot` ]; then
        for i in $(seq 1 10); do
            if [[ 0 -eq `curl -s4 ${IPV6_TUNNEL} 2>&1 >${IPV6_STAT};echo $?` ]]; then
                echo $(basename $0)[$$] ipv6 tunnel is ok
                if [[ 0 -eq `curl -s4 ${IP_CHECK} 2>&1 >${IPV4_FILE};echo $?` ]]; then
                    IPV4_ADDR="$(get_ip_addr ${IPV4_FILE})"
                    post_ip_addr ${IPV4_ADDR} 4
                fi
                if [[ 0 -eq `curl -s6 ${IP_CHECK} 2>&1 >${IPV6_FILE};echo $?` ]]; then
                    IPV6_ADDR="$(get_ip_addr ${IPV6_FILE})"
                    post_ip_addr ${IPV6_ADDR} 6
                fi
                break
            fi
            sleep $SLEEP_S
        done
        if [[ 0 -eq `good_ipv6 ${IPV6_STAT}` ]]; then
            echo $(basename $0)[$$] $(cat ${IPV6_STAT})
        else
            echo $(basename $0)[$$] ipv6 tunnel is failed
        fi
    else
        IPV4_ADDR=$(curl -s4 ${IPV4_ISP})
        ssh ${SSH_LOGGER} "logger -p local3.info -t $(basename $0)[$$] ${IPV4_ADDR}"
        echo $(basename $0)[$$] ${IPV4_ADDR}
    fi

else
    curl -v4 --ssl ${IPV6_TUNNEL}
fi

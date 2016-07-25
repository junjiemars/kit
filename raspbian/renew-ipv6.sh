#!/bin/bash
IPV6_TEST=${IPV6_TEST:-"<domain-test>"}
IPV6_KEY='<ipv6-key>'
IPV6_SN='<ipv6-sn>'
IPV6_TUNNEL=${IPV6_TUNNEL:-"<ipv6-tunnel-renew-url>"}
IPV6_STAT=${IPV6_TUNNEL_STAT:-/tmp/ipv6.stat}
IPV4_ISP=${IPV4_ISP:-"https://api.ipify.org?format=json"}
IP_CHECK=${IP_CHECK:-"http://checkip.dns.he.net"}
IPV4_FILE=${IPV4_FILE:-/tmp/ipv4.addr}
IPV6_FILE=${IPV6_FILE:-/tmp/ipv6.addr}
IPV4_ADDR=
IPV6_ADDR=
HOST_NAME=${HOST_NAME:-"<host-name>"}
HOST_PASS=${HOST_PASS:-"<host-pass>"}
DNS_RENEW=${DNS_RENEW:-"<ddns-renew-url>"}
SSH_OUTGER=${SSH_OUTGER:-"<outer-host>"}
declare -a SSH_OUTER=('<outer-host-0>' '<outer-host-1>')
SLEEP_S=10s

BNAME=$(basename $0)
DEBUG=${DEBUG:-0}
OUT=${OUT:-0}
TYPE=${TYPE:-"DDNS"}
HELP="usage:\t${BASH_SOURCE[0]} <options>\n\
options:\n
    \t[-h]\t\t\thelp\n\
    \t[-t<type>]\t\tddns, tunnel, ping6, etc., default is ddns\n\
    \t[-v]\t\t\tverbose"

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
    local _r4=`curl -s4 ${IPV4_ISP} | sed -e 's/{"ip":"//g' -e 's/"}//g'`
    [ ".${_d4}" = ".${_r4}" ]; echo $?
}

renew_ddns() {
    if [[ 0 -eq `curl -s4 ${IP_CHECK} 2>&1 >${IPV4_FILE};echo $?` ]]; then
        IPV4_ADDR="$(get_ip_addr ${IPV4_FILE})"
        post_ip_addr ${IPV4_ADDR} 4
    fi
    if [[ 0 -eq `curl -s6 ${IP_CHECK} 2>&1 >${IPV6_FILE};echo $?` ]]; then
        IPV6_ADDR="$(get_ip_addr ${IPV6_FILE})"
        post_ip_addr ${IPV6_ADDR} 6
    fi
}

out_inode() {
    IPV4_ADDR=$(curl -s4 ${IPV4_ISP})
    for o in ${SSH_OUTER[@]}; do
        ssh ${o} "logger -p local3.info -t ${BNAME}[$$] ${IPV4_ADDR}"
    done
    echo ${BNAME}[$$] ${IPV4_ADDR}
}

renew_tunnel() {
    for i in $(seq 1 10); do
        if [ "0" != `ping6_check ${IPV6_TEST}` ] || [ "0" != `ipv4_rot` ]; then
            echo ${BNAME}[$$] try to tunnel ipv6...
            if [[ 0 -eq `curl -s4 ${IPV6_TUNNEL} 2>&1 >${IPV6_STAT};echo $?` ]]; then
                echo ${BNAME}[$$] ipv6 tunnel is ok
            fi
            echo "try to renew ddns..."
            renew_ddns
            if [[ 0 -eq `good_ipv6 ${IPV6_STAT}` ]]; then
                echo ${BNAME}[$$] $(cat ${IPV6_STAT})
                echo ${BNAME}[$$] renew ipv6 tunnel is ok
                break;
            else
                echo ${BNAME}[$$] renew ipv6 tunnel is failed
            fi
        else
            echo ${BNAME}[$$] ipv6 tunnel is ready
            break
        fi
        sleep $SLEEP_S
    done
}

while getopts "hvot:" arg
do
    case ${arg} in
        h) echo -e ${HELP}; exit 0;;
        v) DEBUG=1;;
        o) OUT=1;;
        t) TYPE=`echo ${OPTARG} | tr [:lower:] [:upper:]`;;
        *) echo -e ${HELP}; exit 1;;
    esac
done

case ".${TYPE}" in
    .) renew_ddns; [[ 0 -lt ${OUT} ]] && out_inode;;
    .DDNS) renew_ddns; [[ 0 -lt ${OUT} ]] && out_inode;;
    .TUNNEL) renew_tunnel; [[ 0 -lt ${OUT} ]] && out_inode;;
    .PING6) ping6_check ${IPV6_TEST};;
esac

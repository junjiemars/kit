#!/bin/bash
IPV6_TEST=${IPV6_TEST:-"ipv6-test.com"}
IPV6_TUNNEL=${IPV6_TUNNEL:-"<ipv6-tunnel>"}
IPV4_ISP=${IPV4_ISP:-"https://api.ipify.org?format=json"}

if [[ 0 -lt `ping6 -q -c3 ${IPV6_TEST} &> /dev/null;echo $?` ]]; then
    echo -e "$(date) : $(curl -s -4 ${IPV6_TUNNEL})"
    exit 1
else
    echo -e "$(date) : $(curl -s -4 ${IPV4_ISP})"
fi

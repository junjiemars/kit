#!/bin/bash
IPV6_TEST=${IPV6_TEST:-"ipv6-test.com"}
IPV6_TUNNEL=${IPV6_TUNNEL:-"<ipv6-tunnel-url>"}
IPV4_ISP=${IPV4_ISP:-"https://api.ipify.org?format=json"}
SLEEP_S=10s
#`logger -p local3.info -t $(basename $0)[$$] $(curl -s4 ${IPV6_TUNNEL})`

if [[ 0 -lt `ping6 -q -c3 ${IPV6_TEST} 2>&1 >/dev/null;echo $?` ]]; then
    for i in $(seq 1 10); do
        echo $i
        if [[ 0 -eq `curl -s4 ${IPV6_TUNNEL} 2>&1 >/dev/null;echo $?` ]]; then
            echo $(basename $0)[$$] ipv6 tunnel is ok
            break
        fi
        sleep $SLEEP_S
    done
    sleep $SLEEP_S
    echo $(basename $0)[$$] $(curl -s4 ${IPV6_TUNNEL})
else
    echo $(basename $0)[$$] $(curl -s4 ${IPV4_ISP})
fi

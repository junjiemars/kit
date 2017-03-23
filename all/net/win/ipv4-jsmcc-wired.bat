set ip=172.16.10.69
set mask=255.255.255.0
set gw=172.16.10.254
set ifname="Local Area Connection" 
set ifnumber=9
set wip=192.168.0.1
set rip=10.33.208.0
set rmask=255.255.255.0
set dns0=192.168.4.11
set dns1=8.8.4.4
REM set dns1=74.82.42.42

netsh interface ipv4 set address name=%ifname% static %ip% %mask% %gw% 1
netsh interface ipv4 set dnsserver name=%ifname% static %dns0% primary
netsh interface ipv4 add dnsserver name=%ifname% %dns1%

REM set default route table 
route delete 0.0.0.0 
route delete %rip%
route add 0.0.0.0 mask 0.0.0.0 %wip% metric 32
route add %rip% mask %rmask% %gw% metric 64 if %ifnumber%
REM netsh interface ipv4 add route %rip%/8 %ifname% %ip% store=persistent
REM ping 1.1.1.1 -n 1 -w 5000 > nul REM sleep 5s
REM netsh interface ipv4 delete route 10.0.0.0/8 "Local Area connection" 10.32.65.1 
REM netsh interface ipv4 add route 10.0.0.0/8 "Local Area connection" 10.32.65.1 store=active
REM netsh wlan start hostednetwork

REM tereo-debian.remlab.net
REM teredo.ngix.ne.kr
REM teredo.trex.fi

ipconfig /flushdns


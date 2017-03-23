set ip=192.168.50.197
set mask=255.255.255.0
set gw=192.168.50.254
set ifname="Local Area Connection" 
set ifnumber=9
set iip=10.32.149.118
set imask=255.255.255.128
set igw=10.32.149.1
set iipr=10.33.208.0
set imaskr=255.255.255.0
set iipr1=10.32.0.0

set dns0=8.8.4.4
set dns1=74.82.42.42

ipconfig /renew

netsh interface ipv4 set address name=%ifname% static %ip% %mask% %gw% 1
netsh interface ipv4 add address name=%ifname% %iip% %imask% %igw% 2

netsh interface ipv4 set dnsserver name=%ifname% static %dns0% primary
netsh interface ipv4 add dnsserver name=%ifname% %dns1%

ipconfig /flushdns

REM set default route table 
route delete 0.0.0.0 
route delete %iipr%
route delete %iipr1%
route add 0.0.0.0 mask 0.0.0.0 %gw% metric 64 if %ifnumber%
route add %iipr% mask %imaskr% %igw% metric 32 if %ifnumber%
route add %iipr1% mask %imaskr% %igw% metric 33 if %ifnumber%
REM netsh interface ipv4 add route %iipr% mask %imask% %igw% if %ifname% 
REM netsh interface ipv4 add route %iip%/8 %ifname% %ip% store=persistent



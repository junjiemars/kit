set iip=192.168.0.100
set imask=255.255.255.0
set igw=192.168.0.1
set iifnumber=20 
set eifname="Local Area connection" 
set eip=192.168.23.217
set emask=255.255.252.0
set egw=192.168.20.254
set eifnumber=9
set iipr=10.33.208.0
set imaskr=255.255.255.0
set dns0=192.168.4.11
set dns1=74.82.42.42



REM address
netsh interface ipv4 set address name=%eifname% source=dhcp
netsh interface ipv4 set dnsserver name=%eifname% source=dhcp
sleep 3
netsh interface ipv4 set address name=%eifname% static %eip% %emask% %egw% 1

REM dns
netsh interface ipv4 set dnsserver name=%eifname% static %dns0% primary
netsh interface ipv4 add dnsserver name=%eifname%  %dns1%

REM set default route table 
route delete 0.0.0.0 
route delete %eip%
route delete %iip%
route delete %iipr%

route add 0.0.0.0 mask 0.0.0.0 %eip% metric 32 if %eifnumber%
route add %iipr% mask %imaskr% %igw% metric 64 if %iifnumber%


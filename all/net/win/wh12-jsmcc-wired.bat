set ip=10.32.149.118
set mask=255.255.255.128
set gw=10.32.149.1
set ifname="Local Area Connection" 
set ifnumber=9
set wip=192.168.0.1
set rip=10.33.208.0
set rmask=255.255.255.0
set dns0=10.32.149.1
REM set dns1=8.8.4.4
REM set dns1=74.82.42.42

ipconfig /renew

netsh interface ipv4 set address name=%ifname% static %ip% %mask% %gw% 1
netsh interface ipv4 set dnsserver name=%ifname% static %dns0% primary
REM netsh interface ipv4 add dnsserver name=%ifname% %dns1%

ipconfig /flushdns

REM set default route table 



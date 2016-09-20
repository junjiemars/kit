@echo off
set if_name="Local Area Connection"
set dns0=8.8.4.4
set dns1=74.82.42.42

echo "set dhcp ..."
netsh interface ipv4 set address name=%if_name% source=dhcp

echo "set dns server ..."
netsh interface ipv4 set dnsserver name=%if_name% static %dns0% primary
netsh interface ipv4 add dnsserver name=%if_name%  %dns1%

echo "sleep 5s ..."
ping 1.1.1.1 -n 1 -w 5000 > nul

echo "flush dns cache ..."
ipconfig /flushdns

@echo on

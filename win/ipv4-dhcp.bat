set dns0=218.4.4.4
set dns1=74.82.42.42

netsh interface ipv4 set address name="Local Area Connection" source=dhcp

netsh interface ipv4 set dnsserver name="Local Area connection" static %dns0% primary

netsh interface ipv4 add dnsserver name="Local Area Connection"  %dns1%

ping 1.1.1.1 -n 1 -w 5000 > nul REM sleep 5s

ipconfig /flushdns

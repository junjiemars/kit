set ip=<ipv4-addr-1>
REM set ip=<ipv4-addr-2>
set dns0=8.8.4.4
set dns1=74.82.42.42

netsh interface ipv4 set address name="Local Area Connection" static %ip% 255.255.252.0 192.168.20.254 1

netsh interface ipv4 set dnsserver name="Local Area connection" static %dns0% primary

netsh interface ipv4 add dnsserver name="Local Area connection" %dns1%

REM ping 1.1.1.1 -n 1 -w 5000 > nul REM sleep 5s
REM netsh interface ipv4 delete route 10.0.0.0/8 "Local Area connection" 10.32.65.1 
REM netsh interface ipv4 add route 10.0.0.0/8 "Local Area connection" 10.32.65.1 store=active
REM netsh wlan start hostednetwork

ipconfig /flushdns


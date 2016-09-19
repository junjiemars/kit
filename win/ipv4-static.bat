@echo off

set ip=<ipv4-addr-1>
REM set ip=<ipv4-addr-2>
set if_name="Local Area Connection"
set mask="<netmask>"
set gw="<gateway>"
set dns0=8.8.4.4
set dns1=74.82.42.42
set ssid="<ssid>"
set key="<passwd>"

echo "set ipv4 address ..."
netsh interface ipv4 set address name=%if_name% static %ip% %mask% %gw% 1

echo "set dns server ..."
netsh interface ipv4 set dnsserver %if_name% static %dns0% primary
netsh interface ipv4 add dnsserver %if_name% %dns1%

netsh wlan show driver | findstr "Hosted network" | findstr "No"
if errorlevel 0 (
   echo "checking hosted network ...no"
) else (
   echo "set hosted network ..."
   netsh wlan show hostednetwork | findstr %hot_name%
   if errorlevel 1 (
      netsh wlan set hostednetwork mode=allow^
      ssid=%ssid%^
      key=%key% keyusage=pesistent
   )
   echo "start hosted network ..."
   netsh wlan start hostednetwork
)


echo "flush dns cache ..."
ipconfig /flushdns

@echo on

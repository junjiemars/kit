@echo off

REM set ip=192.168.23.89
set ip=192.168.23.217
set if_name="Local Area Connection"
set mask=255.255.252.0
set gw=192.168.20.254
set dns0=8.8.4.4
set dns1=192.168.4.11
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

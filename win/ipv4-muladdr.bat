REM 
@echo on

set eif="Local Area Connection"
set eif_ip0="<primary-ip>"
set eif_mask0="<primvary-mask>"
set eif_gw0="<primary-gateway>"
set eif_ip1="<second-ip>"
set eif_mask1="<second-mask"
set eif_gw1="<second-gateway>"
set dns0=8.8.4.4
set dns1=74.82.42.42

netsh interface ipv4 set address name=%eif% source=dhcp
netsh interface ipv4 set address name=%eif% source=static address=%eif_ip0% mask=%eif_mask0% gateway=%eif_gw0% store=active
netsh interface ipv4 add address name=%eif% address=%eif_ip1% mask=%eif_mask1% gateway=%eif_gw1% store=active skipassource=true
netsh interface ipv4 delete dnsservers name=%eif% address=all
netsh interface ipv4 set dnsservers name=%eif% source=static address=%dns0% validate=no
netsh interface ipv4 add dnsservers name=%eif% address=%dns1% validate=no

netsh interface ipv4 add route prefix=10.33.208.0/24 interface=%eif% nexthop=%eif_gw1% store=active publish=yes



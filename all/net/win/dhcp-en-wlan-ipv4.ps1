##
## DHCP
## Enternet ||  WiFi 
##

$eif = Get-NetAdapter -Name:"Local Area connection"
#$wif = Get-NetAdapter -Name:"Wi-Fi"

$dns0 = '192.168.4.11'
$dns1 = '74.82.42.42'

# Enable dhcp first
$eif | Set-NetIPInterface -Dhcp Enabled
#$wif | Set-NetIPInterface -Dhcp Enabled

$eif | Set-DNSClientServerAddress -ServerAddresses:($dns0,$dns1) `
                                  -ErrorAction:Continue `
                                  -Confirm:$false
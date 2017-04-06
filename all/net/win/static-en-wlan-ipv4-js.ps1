##
## STATIC
## Enternet && Wlan
##

$eif = Get-NetAdapter -Name:"Local Area connection"
#$eif_ip = 192.168.23.89
$eif_ip = '192.168.23.217'
$eif_mask = '255.255.252.0'
$eif_ip_prefix_len = 16
$eif_gw = '192.168.20.254'

$dns0 = '192.168.4.11'
$dns1 = '74.82.42.42'

$wif = Get-NetAdapter -Name:"Wi-Fi"
$wif_ip = '192.168.0.100'
$wif_gw = '192.168.0.1'
$wif_ip_prefixes = ('10.32.0.0/16', '10.33.0.0/16')


# Enable dhcp first
$eif | Set-NetIPInterface -Dhcp:Enabled
$wif | Set-NetIPInterface -Dhcp:Enabled

# Remove enternet default ip address
$ip = $eif | Get-NetIPAddress -AddressFamily:IPv4 
if ($ip) {
  $eif | Remove-NetIPAddress -IPAddress:$ip.IPAddress `
                             -AddressFamily:IPv4 `
                             -Confirm:$false
}

# Remove enternet default route
$eif_dgw = $eif | Get-NetRoute -DestinationPrefix:'0.0.0.0/0' `
                               -ErrorAction:Continue 
if ($eif_dgw) {
  Remove-NetRoute -DestinationPrefix:'0.0.0.0/0' `
                  -InterfaceIndex:$eif.ifIndex `
                  -NextHop:$eif_dgw.NextHop `
                  -Confirm:$false
} 

# New enternet ip address
$eif | New-NetIPAddress -IPAddress:$eif_ip `
                        -PrefixLength:$eif_ip_prefix_len `
                        -DefaultGateway:$eif_gw `
                        -Confirm:$false

# New enternet dns
$eif | Set-DNSClientServerAddress -ServerAddresses:($dns0,$dns1) `
                                  -ErrorAction:Continue `
                                  -Confirm:$false

# Remove wifi default route
$wif_dgw = $wif | Get-NetRoute -DestinationPrefix:'0.0.0.0/0' `
                               -ErrorAction:Continue
if ($wif_dgw) {
  Remove-NetRoute -DestinationPrefix:'0.0.0.0/0' `
                  -InterfaceIndex:$wif.ifIndex `
                  -NextHop:$wif_dgw.NextHop `
                  -Confirm:$false
}

# Remove wifi specified route
foreach ($ip_prefix in $wif_ip_prefixes) {
  $wif_dgw = $null
  $wif_dgw = $wif | Get-NetRoute -DestinationPrefix:$ip_prefix `
                                 -ErrorAction:Continue
  if ($wif_dgw -and $wif_dgw.DestinationPrefix -eq $ip_prefix) {
    Remove-NetRoute -DestinationPrefix:$ip_prefix `
                    -InterfaceIndex:$wif.ifIndex `
                    -NextHop:$ip_prefix `
                    -Confirm:$false
  }
  $wif | New-NetRoute -DestinationPrefix:$ip_prefix `
                      -NextHop:$wif_gw `
                      -Confirm:$false
}
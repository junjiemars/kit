##
## STATIC
## Enternet: multiple IP addresses
## 

$eif = Get-NetAdapter -Name:"Local Area connection"

$eif_ip0 = '192.168.23.217' 
$eif_ip1 = '192.168.23.89'

$eif_ip_primary = $eif_ip1
$eif_ip_second = $eif_ip0

$eif_mask = '255.255.252.0'
$eif_ip_prefix_len = 16 
$eif_gw = '192.168.20.254'

$dns0 = '192.168.4.11'
$dns1 = '74.82.42.42'

# Enable dhcp first
$eif | Set-NetIPInterface -Dhcp:Enabled

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

$eif | New-NetIPAddress -IPAddress:$eif_ip_primary `
                        -PrefixLength:$eif_ip_prefix_len `
                        -DefaultGateway:$eif_gw 

if ($eif_ip_second) {
    $eif | New-NetIPAddress -IPAddress:$eif_ip_second `
                            -PrefixLength:$eif_ip_prefix_len `
                            -SkipAsSource:$false
}
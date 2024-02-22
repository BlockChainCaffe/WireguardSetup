# Settings

## VPN Name
VPNNAME='Blockchain Caffe'

## Public IP of this server
PUBLICIP=$(curl ifconfig.io)   # curl -s https://checkip.amazonaws.com

## Iterface that uses the default gateway -> internet
PUBLICETH=$(ip route  | grep default | sed "s/^.*dev //" | sed "s/ .*$//")

## Public DNS name for the server, if any
PUBLICURL=""

## Port the Wireguard server will be listening on
PUBLICPORT="33223"

## Network shared by all nodes of the VPN, just class C octects
VPNNET_CLASS_C="10.20.0"

## Possible DNS Values
DNS="8.8.8.8, 8.8.4.4"                  # Google
#DNS="1.1.1.1, 1.0.0.1"                 # CloudFlare
#DNS="208.67.222.222, 208.67.220.220"   # OpenDNS
#DNS="9.9.9.9, 149.112.112.112"         # Quad9
#DNS="94.140.14.14, 94.140.15.15"       # AdGuard

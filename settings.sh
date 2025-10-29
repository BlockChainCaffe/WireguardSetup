# Settings


## Public IP of this server
export PUBLICIP=$(curl -s ifconfig.io)   # curl -s https://checkip.amazonaws.com
## Iterface that uses the default gateway -> internet
export PUBLICETH=$(ip route  | grep default | sed "s/^.*dev //" | sed "s/ .*$//")
## Public DNS name for the server, if any
export PUBLICURL=""

## Possible DNS Values
export DNS="8.8.8.8, 8.8.4.4"                  # Google
#DNS="1.1.1.1, 1.0.0.1"                 # CloudFlare
#DNS="208.67.222.222, 208.67.220.220"   # OpenDNS
#DNS="9.9.9.9, 149.112.112.112"         # Quad9
#DNS="94.140.14.14, 94.140.15.15"       # AdGuard

## VPN Name
export VPNNAME='Blockchain Caffe'
## Port the Wireguard server will be listening on
export VPNPORT="33223"
## Network shared by all nodes of the VPN, just class C octects
export VPNNET_CLASS_C="10.20.0"


## Endlessh start listen port
export ENDLESS_PORT=2222
## Real ssh server port (once endless is on 22)
export REALSSHPORT=2552



## Print data only if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo 'Your server setup values:'
    echo -e '\tPublic ip address:\t\t'$PUBLICIP
    echo -e '\tPublic interface: \t\t'$PUBLICETH
    echo -e '\tServer Url:\t\t\t'$PUBLICURL
    echo
    echo 'Wireguard VPN settings'
    echo -e '\tVPN Network name:\t\t'$VPNNAME
    echo -e '\tVPN Class C network:\t\t'$VPNNET_CLASS_C'.1/24'
    echo -e '\tVPN server port:\t\t'$VPNPORT
    echo
    echo 'Initial endlessh values'
    echo -e '\tListen port:\t\t\t'$ENDLESS_PORT
    echo -e '\tReal SSH port:\t\t\t'$REALSSHPORT
fi
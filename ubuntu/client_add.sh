#!/bin/bash

# Settings
source ../settings.sh

# Check this is run by root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root."
    exit 1
fi

if [[ $# != 1 ]]; then
    echo "Provide a name for the client"
    exit
fi
NAME=$1

# Create Private and public keys for client
mkdir /root/Wireguard/clients/$NAME
wg genkey | tee /root/Wireguard/clients/$NAME/privatekey | wg pubkey > /root/Wireguard/clients/$NAME/publickey
chmod 600 /root/Wireguard/clients/$NAME/*

## Get client number -> ip
K=$(cat /etc/wireguard/wg0.conf | grep Peer | wc -l)
K=$(( K + 10 ))

if (( "x$PUBLICURL" != "x" )); then
    ENDPOINT=$PUBLICURL
else
    ENDPOINT=$PUBLICIP
fi

## Add Peer configuration to Server wg0
TMP=$(mktemp)
pK=$(cat /root/Wireguard/clients/$NAME/publickey)
cat ../peer_wg0.conf                        | \
    sed "s:%%CLIENT_NAME%%:$NAME:"          | \
    sed "s:%%CLASS_C%%:$VPNNET_CLASS_C:"    | \
    sed "s:%%K%%:$K:"                       | \
    sed "s:%%CLIENT_PUBKEY%%:$pK:"            \
    > $TMP
echo >> /etc/wireguard/wg0.conf
cat $TMP >> /etc/wireguard/wg0.conf
rm -f $TMP


## Create configuration files for client
TMP=$(mktemp)
PK=$(cat /root/Wireguard/clients/$NAME/privatekey)
pK=$(cat /root/Wireguard/keys/publickey)
# Connon configuration parameters
cat ../client_wg0.conf                      | \
    sed "s:%%CLIENT_NAME%%:$NAME:"          | \
    sed "s:%%SERVER_NAME%%:$VPNNAME:"       | \
    sed "s:%%ENDPOINT%%:$ENDPOINT:"         | \
    sed "s:%%PORT%%:$PUBLICPORT:"           | \
    sed "s:%%CLIENT_PK%%:$PK:"              | \
    sed "s:%%CLASS_C%%:$VPNNET_CLASS_C:"    | \
    sed "s:%%K%%:$K:"                       | \
    sed "s:%%SERVER_pK%%:$pK:"                \
    > $TMP

# Configuration wg0: Just connect to lan 
cat $TMP | sed "s:%%IPS%%:$VPNNET_CLASS_C.0/24, $DNS:"  |\
    sed "s:%%DNS%%:$DNS:"                   | \
> /root/Wireguard/clients/$NAME/wg0.conf

# Configuraion wg0A: Captive: route all traffic via VPN and resovle DNS with blocky
cat $TMP | sed "s:%%IPS%%:0.0.0.0/0:"       | \
    sed "s:%%DNS%%:$VPNNET_CLASS_C.1:"      | \
> /root/Wireguard/clients/$NAME/wg0A.conf

rm -f $TMP

cd /root/Wireguard/clients/
tar -zcf $NAME.tgz $NAME
mv $NAME.tgz $NAME

# Reload wg0 configuration with new client
wg-quick down wg0
wg-quick down wg0

echo ""
echo "Configuration files for client are in /root/Wireguard/clients/$NAME/$NAME.tgz

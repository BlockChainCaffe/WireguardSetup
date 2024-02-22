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
cat ../client_wg0.conf                      | \ 
    sed "s:%%CLIENT_NAME%%:$NAME:"          | \
    sed "s:%%SERVER_NAME%%:$VPNNAME:"       | \
    sed "s:%%ENDPOINT%%:$ENDPOINT:"         | \
    sed "s:%%PORT%%:$PUBLICPORT:"           | \
    sed "s:%%CLIENT_PK%%:$PK:"              | \
    sed "s:%%CLASS_C%%:$VPNNET_CLASS_C:"    | \
    sed "s:%%K%%:$K:"                       | \
    sed "s:%%DNS%%:$DNS:"                   | \
    sed "s:%%SERVER_pK%%:$pK:"                \
    > $TMP

cat $TMP | sed "s:%%IPS%%:$VPNNET_CLASS_C.0/24:"  >> /root/Wireguard/clients/$NAME/wg0.conf
cat $TMP | sed "s:%%IPS%%:0.0.0.0:" >> /root/Wireguard/clients/$NAME/wg0A.conf
rm -f $TMP

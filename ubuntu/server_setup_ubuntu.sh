#!/bin/bash

# Settings
source ../settings.sh

# Check this is run by root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root."
    exit 1
fi

# Check that the module is in the kernel
modprobe wireguard
if [[ $? != 0 ]]; then
    echo "Wireguard module is not in the kernel"
    exit 1
fi

# System setup & Requirements
apt-get -yqq update && apt-get -yqq upgrade
apt-get -yqq install wget >/dev/null
apt-get -yqq install iproute2 >/dev/null

# Intall Wireguard
apt-get -yqq install wireguard wireguard-tools

# Kernel tuning
cp /etc/sysctl.conf /etc/sysctl.conf_BKP
sysctl -w net.ipv4.ip_forward=1 
sysctl -w net.ipv6.conf.defaut.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv4.conf.all.proxy_arp=1
sysctl -a > /etc/sysctl.conf
sysctl -p

# Create dir
mkdir /root/Wireguard
mkdir /root/Wireguard/keys
mkdir /root/Wireguard/clients

# Create server private & public keys
wg genkey | tee /root/Wireguard/keys/privatekey | wg pubkey > /root/Wireguard/keys/publickey
chmod 600 /root/Wireguard/keys/*

# Create Server config file
cat ../server_wg0.conf | \
    sed "s:%%SERVER_NAME%%:$VPNNAME:" | \
    sed "s:%%PORT%%:$PUBLICPORT:" | \
    sed "s:%%CLASS_C%%:$VPNNET_CLASS_C:" | \
    sed "s:%%DEV%%:$PUBLICETH:" \
    > /etc/wireguard/wg0.conf

# Enable service
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service

# Bring interface up
wg-quick up wg0
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
    echo "Wirequadr module is not in the kernel"
    exit 1
fi

# System setup & Requirements
add-apt-repository ppa:wireguard/wireguard
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
sysctl -a > /etc/sysctl.conf
sysctl -p

# Firewall settings (iptables)


# Create proper dir
mkdir /root/Wireguard
mkdir /root/Wireguard/keys
mkdir /root/Wireguard/clients

# Server private & public ket generation
wg genkey | tee /root/Wireguard/keys/privatekey | wg pubkey > /root/Wireguard/keys/publickey
chmod 600 /root/Wireguard/keys/*

# Create Server config file
cat ../server_wg0.conf | \
    sed "s:%%SERVER_NAME%%:$VPNNAME:" | \
    sed "s:%%PORT%%:$PUBLICPORT:" | \
    sed "s:%%CLASS_C%%:$VPNNET_CLASS_C:" \
    > /etc/wireguard/wg0.conf

# Enable service
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service

#!/bin/bash

# Disable service
systemctl stop wg-quick@wg0
systemctl disable --now wg-iptables.service

rm -f /etc/systemd/system/wg-iptables.service

# Remove configuration files
rm -rf /etc/wireguard

# Remove packages
apt-get remove --purge -y wireguard wireguard-tools >/dev/null
apt-get autoremove

#!/bin/bash
#       IP TABLES GENERIC FIREWALL SCRIP (server)
#
# 1.1: To inspect firewall with line numbers, enter:
# iptables -n -L -v --line-numbers
#
# 2: Stop / Start / Restart the Firewall
# service iptables stop
# service iptables start
# service iptables restart
#

#####################################################################
#       VARS
# Main internet facing interface
MAINETH="%%PUBLICETH%%"

# Interfaces allowed (any connection from any IP)
WHITEETH="lo wg0"

# Ip addresses allowed (any connection)
WHITEIP="46.252.154.117"

# Ports listening (incoming connections from any IP on any interface)
WHITEPORT_DST="22 %%VPNPORT%% %%REALSSHPORT%%"

# Allow 'combos': in the form [ip];[port] means this ip can connect to this port
WHITECOMBO=""

#####################################################################
#
#       SCRIP : static part
#

# Delete (flush) all the rules.
iptables -F

# Set the Default Firewall Policies
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Accept ongoing connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop Private Network Address On Public Interface
iptables -A INPUT -i $MAINETH -s 192.168.0.0/16 -j DROP
iptables -A INPUT -i $MAINETH -s 10.0.0.0/16 -j DROP
iptables -A INPUT -i $MAINETH -s 127.0.0.0/16 -j DROP
iptables -A INPUT -i $MAINETH -s 172.0.0.0/16 -j DROP


#####################################################################
#
#       SCRIP : dynamic part
#

# Allow all traffic to specific network adapters
for ETH in $WHITEETH
do
    iptables -A INPUT -i $ETH -j ACCEPT
done

# Allow all traffic from specific IPs (BF4E)
for IP in $WHITEIP
do
    iptables -A INPUT -i $MAINETH -s $IP -j ACCEPT
done

# Allow public traffic to allowed ports DESTIANTION (localhost is server)
for PORT in $WHITEPORT_DST
do
    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
done

# Allow specific source/ports traffic (Combos)
for COMBO in $WHITECOMBO
do
    NET=$(echo $COMBO | cut -d';' -f1)
    PORT=$(echo $COMBO | cut -d';' -f2)

    iptables -A INPUT -p tcp -s $NET --dport $PORT -j ACCEPT
done

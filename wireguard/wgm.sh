#!/bin/bash
set -x

BANNER='
###############################################################################

            ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓██████████████▓▒░  
            ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
            ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
            ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒▒▓███▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
            ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
            ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
             ░▒▓█████████████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░           
                                                       
    WGM: Wireguard manager
    Simple script to handle wireguard configuration, client generation etc
                                                       
###############################################################################
'

DISCLAIMER='
VPN Usage Disclaimer

This VPN script is provided "as is" without any warranties or guarantees. 
By using this service, you acknowledge and agree that:

1. You are solely responsible for your activities while connected to this VPN.

2. The VPN script provider assumes no liability for any illegal activities, 
   misuse, or any damages arising from your use of this service.

3. You agree to comply with all applicable laws and regulations in your 
   jurisdiction while using this VPN.

4. The provider is not responsible for any data loss, security breaches, 
   service interruptions, or any direct or indirect damages resulting from 
   VPN usage.

5. You use this service at your own risk. The provider makes no guarantees 
   regarding privacy, security, speed, or availability.

6. The provider reserves the right to terminate access at any time without 
   notice.

By using this VPN, you accept these terms in full.'

###############################################################################
# Globals

VERSION="WGM Wireguard Manager V. 0.1.3"
CFG_DIR="/root/Wireguard_WGM"

IPADDRESS_PROVIDERS=(
  "https://ifconfig.io"
  "https://ifconfig.me"
  "https://checkio.amazonaws.com"
  "https://ipaddress.sh"
  "https://icanhazip.com"
)


###############################################################################
# Helper Functions


# whiptail wrapper function
wt() {
  # Run whiptail with redirected file descriptors so output can be captured
  local RESULT
  RESULT=$(whiptail --backtitle "$VERSION" "$@" 3>&1 1>&2 2>&3)
  local STATUS=$?

  # If canceled or failed, print error to stderr and return non-zero
  if [ $STATUS -ne 0 ]; then
    echo "Whiptail cancelled or failed." >&2
    return $STATUS
  fi

  # Otherwise print the result (so it can be captured by the caller)
  echo "$RESULT"
  return 0
}


# Check if whiptail is installed, otherwise installs it
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        echo "Whiptail not found."

        # Ask user for permission using a simple terminal prompt first
        read -p "Whiptail is not installed. Do you want to install it now? [Y/n] " choice
        choice=${choice:-Y}

        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo "Installing whiptail..."
            sudo apt-get update -y && sudo apt-get install -y whiptail

            # Verify installation success
            if ! command -v whiptail &> /dev/null; then
                echo "Installation failed. Please install whiptail manually."
                exit 1
            fi
            echo "Whiptail installed successfully."
        else
            echo "Installation cancelled by user."
            exit 1
        fi
    fi
}


# Get external IP address based on multiple sources
# Returns the "agreed upon" IP address via echo
get_external_ip() {
    tmpfile=$(mktemp)
    > "$tmpfile"  # ensure empty
    for url in "${IPADDRESS_PROVIDERS[@]}"; do
        {
            # Get response, strip whitespace/newlines, append to tmp file
            curl -s "$url" | tr -d '[:space:]' >> "$tmpfile"
            echo >> "$tmpfile"  # ensure each response is on a new line
        } &
    done

    # Wait for all background jobs to finish
    wait
    PUBLICIP=$(cat "$tmpfile" | sort | uniq | grep -v '^[[:space:]]*$' )
    PUBLICIP=$(wt  --title "Your external IP"\
        --inputbox "Please check here and insert your external IP address"\
        8 80\
        $PUBLICIP)
    # echo $PUBLICIP
}


create_folders() {
    # Create dir
    mkdir $CFG_DIR 2>&1 >> /dev/null
    mkdir $CFG_DIR/keys 2>&1 >> /dev/null
    mkdir $CFG_DIR/clients 2>&1 >> /dev/null
}


###############################################################################
# Installation

update_system() {
    YN=$(wt --title "Update System?"\
            --yesno "Do you want to update the system before continuing? (this might take a while...)" \
            8 80
        )
    if [[ "$?" == 0 ]]; then
        {
        echo 5
        # System setup & Requirements
        apt-get -yqq update >> /dev/null 2>&1 
        apt-get -yqq upgrade >> /dev/null 2>&1 
        } | whiptail --gauge "System update in progress" 8 70 0
    fi
}

install_wg() {

    # Run apt-get update?
    update_system

    {   
        echo 35
        # Install requirements
        apt-get -yqq install wget >/dev/null
        apt-get -yqq install iproute2 >/dev/null
        apt-get -yqq install openresolv                 # TBD add to client script
        apt-get -yqq install qrencode

        echo 50
        # Install wireguard
        apt-get -yqq install wireguard wireguard-tools >> /dev/null 2>&1 
 
        echo 70
        # Kernel tweaks
        cp /etc/sysctl.conf /etc/sysctl.conf_BKP
        sysctl -w net.ipv4.ip_forward=1 
        sysctl -w net.ipv6.conf.defaut.forwarding=1
        sysctl -w net.ipv6.conf.all.forwarding=1
        sysctl -w net.ipv4.conf.all.proxy_arp=1
        sysctl -a > /etc/sysctl.conf
        sysctl -p

        echo 80
        # Config direcory
        create_folders

        echo 90
        # Create server private & public keys
        if [ -z "$(find $CFG_DIR/keys/ -mindepth 1 -maxdepth 1)" ]; then
            wg genkey | tee $CFG_DIR/keys/privatekey | wg pubkey > $CFG_DIR/keys/publickey
            chmod 600 $CFG_DIR/keys/*
        fi

        echo 100
        #Done
    } | whiptail --gauge "Installation Progress" 8 70 0
}


uninstall_wg() {
    YN=$(wt --title "DANGER"\
        --yesno "WARNING: this will destroy the VPN. This is irreversible. Are you sure you want to continue?" \
        --defaultno\
        8 80
    )
    if [[ "$?" == 0 ]]; then
        rm -Rf "$CFG_DIR"
        rm -Rf "/etc/wireguard/*"
    fi

}

###############################################################################
# Menù functions


display_settings() {
    CFG_FILE=$CFG_DIR/settings.conf
    return $(wt --title "Your new configuration"\
       --textbox $CFG_FILE 28 80)
}



write_conf() {
    CFG_FILE="/etc/wireguard/wg0.conf"
    mkdir -p "/etc/wireguard"
    rm -Rf $CFG_FILE
    cat << EOF > $CFG_FILE
[Interface]
# Name = $VPNNAME
# PrivateKey = # Added with PostUp command later
Address = $VPNNET_CLASS_C.1/24
SaveConfig = false
ListenPort = $VPNPORT

PostUp = wg set %i private-key $CFG_DIR/keys/privatekey

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o $PUBLICETH -j MASQUERADE
PostUp = ip6tables -t nat -A POSTROUTING -o $PUBLICETH -j MASQUERADE

PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o $PUBLICETH -j MASQUERADE
PostDown = ip6tables -t nat -D POSTROUTING -o $PUBLICETH -j MASQUERADE
EOF
}

## Creates configuration file
create_settings() {
    source $CFG_DIR/settings.conf
    # Get server Public IPV4 address
    get_external_ip

    ## Get default gateway interface
    PUBLICETH=$(ip route | grep default | sed "s/^.*dev //" | sed "s/ .*$//")
    PUBLICETH=$(wt  --title "Your external NIC"\
        --inputbox "Please check here and insert your external facing NIC"\
        8 80\
        $PUBLICETH)

    ## Get Public DNS name
    YN=$(wt --title "Public DNS name"\
            --yesno "Does this server have a DNS name you want to use instead of it's IP address?" \
            8 80
        )
    if [[ "$?" == 0 ]]; then
        PUBLICURL=$(wt  --title "Public DNS name"\
            --inputbox "Insert the public DNS name for this server"\
            8 80)
        RESOLVE=$(dig +short $PUBLICURL)
        if [[ "$RESOLVE" != "$PUBLICURL" ]]; then
            wt  --title "DNS/IP mismatch" \
                --msgbox "The DNS name you inserted does not resolve to your IP. Cannot continue" \
                8 80
            exit 1
        fi
    else   
        PUBLICURL=""
    fi

    ## Get DNS Server to use
    DNS=$(wt --title "Pick a DNS Server" \
            --radiolist "Choose user's DNS" 20 78 8 \
            "208.67.222.222, 208.67.220.220" "OpenDNS" ON \
            "8.8.8.8, 8.8.4.4"               "Google" OFF \
            "1.1.1.1, 1.0.0.1"               "CloudFlare" OFF \
            "9.9.9.9, 149.112.112.112"       "Quad9" OFF \
            "94.140.14.14, 94.140.15.15"     "AdGuard" OFF)

    ## Get VPN Name
    VPNNAME=$(wt --title "Your VPN name"\
                --inputbox "Give a name to your VPN ($VPNNAME)"\
                8 80\
                ${VPNNAME:-"nowhereland"})

    ## Get VPN Class C
    VPNNET_CLASS_C=$(wt  --title "Your VPN Class-C"\
            --inputbox "What \"Class-C\" network will your VPN run on? If you have no idea the default should do"\
            8 80\
            ${VPNNET_CLASS_C:-"10.20.0"})

    ## Get VPN Port
    RND=$(( ( RANDOM % 76 ) + 9024 ))
    VPNPORT=$(wt --title "Your VPN Port"\
                --inputbox "What port will your VPN Server be listeing on? Be sure this port is not blocked by firewall, nat, DMZ or router"\
                8 80\
                ${VPNPORT:-$RND})

    ## Create config foldes and file
    create_folders
    CFG_FILE=$CFG_DIR/settings.conf
    rm -Rf $CFG_FILE 2>&1 >> /dev/null
    echo "PUBLICIP=$PUBLICIP" >> $CFG_FILE
    echo "PUBLICETH=$PUBLICETH" >> $CFG_FILE
    echo "PUBLICURL=$PUBLICURL" >> $CFG_FILE
    echo "DNS='$DNS'" >> $CFG_FILE
    echo "VPNNAME=$VPNNAME" >> $CFG_FILE
    echo "VPNNET_CLASS_C=$VPNNET_CLASS_C" >> $CFG_FILE
    echo "VPNPORT=$VPNPORT" >> $CFG_FILE

    ## Display
    display_settings

    ## Write config to file
    YN=$(wt --title "Write Settings"\
        --yesno "Are you OK with this settings and want to write them to Wireguard config file?" \
        --defaultno\
        8 80
    )
    if [[ "$?" == 0 ]]; then
        write_conf
    fi
}


add_client() {
    # loop until a valid client name is provided
    PATTERN='^[a-zA-Z0-9]*$'
    while true; do
        CLIENT_NAME=$(wt  --title "New Client Name"\
                --inputbox "Give a name to the new client. Use uppercase, lowercase and numbers. Don't use spaces or punctuation etc."\
                8 80)
        if [[ $? != 0 ]]; then
            return 1
        fi
        if [[ $CLIENT_NAME =~ $PATTERN ]]; then
            break
        fi
        wt  --title "Invalid name for client" \
            --msgbox "Use uppercase, lowercase and numbers. Don't use spaces or punctuation etc." \
        8 80
    done

    # Create Private and public keys for client
    mkdir $CFG_DIR/clients/$CLIENT_NAME
    wg genkey | tee $CFG_DIR/clients/$CLIENT_NAME/privatekey | wg pubkey > $CFG_DIR/clients/$CLIENT_NAME/publickey
    chmod 600 $CFG_DIR/clients/$CLIENT_NAME/*

    ## Get client number -> ip
    K=$(cat /etc/wireguard/wg0.conf | grep Peer | wc -l)
    K=$(( K + 10 ))

    if (( "x$PUBLICURL" != "x" )); then
        ENDPOINT=$PUBLICURL
    else
        ENDPOINT=$PUBLICIP
    fi

    ## Add new peer to config file
    TMP=$(mktemp)
    pK=$(cat $CFG_DIR/clients/$CLIENT_NAME/publickey)
    cat << EOF > $TMP
[Peer]
# Name = $CLIENT_NAME
AllowedIPs = $VPNNET_CLASS_C.$K/32
PublicKey = $pK
PersistentKeepalive = 25
EOF
    echo >> /etc/wireguard/wg0.conf
    cat $TMP >> /etc/wireguard/wg0.conf
    rm -f $TMP

    ## Create configuration files for client
    TMP=$(mktemp)
    PK=$(cat $CFG_DIR/clients/$CLIENT_NAME/privatekey)
    pK=$(cat $CFG_DIR/keys/publickey)
# Connon configuration parameters
    cat << EOF > $TMP
[Interface]
# Name = $CLIENT_NAME
PrivateKey = $PK
Address = $VPNNET_CLASS_C.$K/24
DNS = %%DNS%%

[Peer]
# Name = $VPNNAME
Endpoint = $ENDPOINT:$VPNPORT
PublicKey = $pK
AllowedIPs = %%IPS%%
PersistentKeepalive = 30
EOF
    # Configuration wg0: Just connect to lan 
    cat $TMP | sed "s:%%IPS%%:$VPNNET_CLASS_C.0/24:"  |\
        sed "s:%%DNS%%:$DNS:" \
    > $CFG_DIR/clients/$CLIENT_NAME/wg0.conf

    # Configuraion wg0A: Captive: route all traffic via VPN 
    # and resovle DNS with local DNS (blocky, pi-hole etc)
    cat $TMP | sed "s:%%IPS%%:0.0.0.0/0:"       | \
        sed "s:%%DNS%%:$VPNNET_CLASS_C.1:" \
    > $CFG_DIR/clients/$CLIENT_NAME/wg0A.conf

    rm -f $TMP

    # Reload wg0 configuration with new client
    wg-quick down wg0
    wg-quick up wg0


    # Display QRCodes
    clear
    qrencode -t utf8i < $CFG_DIR/clients/$CLIENT_NAME/wg0.conf > $CFG_DIR/clients/$CLIENT_NAME/wg0_qr.txt
    echo "Scan this QR code with WireGuard app for SPLIT tunnel"
    cat $CFG_DIR/clients/$CLIENT_NAME/wg0_qr.txt
    read -p "Press Enter to continue..."
    
    clear
    qrencode -t utf8i < $CFG_DIR/clients/$CLIENT_NAME/wg0A.conf > $CFG_DIR/clients/$CLIENT_NAME/wg0A_qr.txt
    echo "Scan this QR code with WireqGuard app for FULL tunnel"
    cat $CFG_DIR/clients/$CLIENT_NAME/wg0A_qr.txt
    read -p "Press Enter to continue..."


    cat << EOF > $CFG_DIR/clients/$CLIENT_NAME/install.sh
apt-get -yqq install wireguard wireguard-tools
apt-get -yqq install openresolv
mkdir /etc/wireguard
cp *.conf /etc/wireguard
EOF


cat << EOF > $CFG_DIR/clients/$CLIENT_NAME/README.txt

$BANNER

This folder contains your configuration files for the "$VPNNAME" VPN 
and contains: 

 - README.txt : this file
 - install.sh : an install script for Debian based clients
 - privatekey : private encription key. Put somewhere safe
 - publickey  : public key
 - wg*.*      : configuration files

About the configuration files:
You can access the "$VPNNAME" VPN in two modes: split and full tunnel


Split tunnel: 
Only traffic to services inside the VPN goes through the VPN. 
Everything else goes directly through your normal internet connection.
Faster, generally used by "road warriors". Not for privacy

 - wg0.conf: import this configuration file in your client, or
 - wg0_qr.txt: scan this qrcode with your phone

Full tunnel: 
All internet traffic is routed through the VPN. This is used for 
complete privacy. 

 - wg0A.conf: import this configuration file in your client, or
 - wg0A_qr.txt: scan this qrcode with your phone

$DISCLAIMER

EOF
    ## Create conf packet
    tar -zcf $CFG_DIR/clients/$CLIENT_NAME.tgz -C $CFG_DIR/clients/ $CLIENT_NAME

    wt  --title "Configuration done" \
        --msgbox "Configuration files for client are in $CFG_DIR/clients/$CLIENT_NAME.tgz." \
        8 80
}


show_status() {

    REPORT=""
    ## Chec conf file
    if [[ -d "$CFG_DIR/" ]]; then
        REPORT=$REPORT"  Configuration folder present\n"
    else
        REPORT=$REPORT"x Configuration folder missing\n"
    fi

    if [[ -f "$CFG_DIR/settings.conf" ]]; then
        REPORT=$REPORT"  Settings file present\n"
    else
        REPORT=$REPORT"x Settings file missing\n"
    fi

    if [[ -f "$CFG_DIR/keys/privatekey" ]]; then
        REPORT=$REPORT"  Private Key present\n"
    else
        REPORT=$REPORT"x Private Key missing\n"
    fi

    if [[ -f "$CFG_DIR/keys/publickey" ]]; then
        REPORT=$REPORT"  Public Key present\n"
    else
        REPORT=$REPORT"x Public Key missing\n"
    fi


    if [ -n "$(ls /etc/wireguard/wg0.conf)" ]; then
        REPORT=$REPORT"  Configuration file present\n"
    else
        REPORT=$REPORT"x Configuration file missing\n"
    fi

    REPORT=$REPORT"\nRunning:"
    REPORT=$REPORT"\n"$(wg)

    wt --title "Your VPN Server status"\
        --scrolltext\
        --msgbox $"$REPORT" 28 80

}


show_updown() {
    RUNNING=$(wg)
    REPORT=""
    if [[ "$RUNNING" == "" ]]; then
        REPORT="Wireguard server is NOT running"
    else
        REPORT=$REPORT"\nRunning:"
        REPORT=$REPORT"\n"$(wg) 
    fi
    wt --title "Your VPN Server status"\
        --scrolltext\
        --msgbox $"$REPORT" 28 80
}


listusers() {
    LIST=$(find $CFG_DIR/clients/ -mindepth 1 -maxdepth 1 -type d  | sed "s:^.*/::")
    wt --title "Your Clients"\
        --scrolltext\
        --msgbox $"$LIST" 28 80
}


remove_1_user() {
    CFG_FILE='/etc/wireguard/wg0.conf'
    user=$1
    LINE="# Name = $user"
    MATCH_LINE=$(grep -n "$LINE" "$CFG_FILE" | head -1 | cut -d: -f1)
    START_LINE=$((MATCH_LINE - 1))
    END_LINE=$((MATCH_LINE + 3))
    sed -i "${START_LINE},${END_LINE}d" "$CFG_FILE"
}


removeusers() {
    LIST=$(find $CFG_DIR/clients/ -mindepth 1 -maxdepth 1 -type d  | sed "s:^.*/::")
    LIST=($LIST)
    CHECKLIST_ARGS=()
    for user in "${LIST[@]}"; do
        CHECKLIST_ARGS+=("$user" "" OFF)  # word, description, default status
    done

    SELECTED=$(wt --title "Select users to delete"\
                    --checklist "Choose one or more" 18 80 10\
                    "${CHECKLIST_ARGS[@]}")

    echo $SELECTED
    for user in $SELECTED; do
        user=$(echo $user | tr -d "\'\"")
        echo $user
        ##  Extract tgz archive
        rm -Rf $CFG_DIR/clients/$user.tgz $CFG_DIR/clients/$user
        ## Remove the config files
        remove_1_user $user
    done
    wg-quick down w0
    wg-quick up w0
}

###############################################################################
# Main Menù

main_menu() {
    while true; do
        source $CFG_DIR/settings.conf
        echo $DNS
        CHOICE=$(wt --title "WGM Main Menu" --menu "Choose an option:" 20 58 14 \
            "Settings" "Display the current settings" \
            "Configure" "Change/Update the configuration settings" \
            " " " "\
            "Status" "Show status of VPN"\
            "Start" "Start Wireguard VPN"\
            "Stop" "Stop Wireguard VPN"\
            "Install" "Force Reinstall"\
            " " " "\
            "ListUsers" "List all users on the VPN." \
            "AddUsers" "Add a user group to the VPN." \
            "RemoveUser" "Block users from accessing" \
            "RemoveVPN" "Remove the Wireguard VPN from this server"\
            " " " "\
            "Exit" "Exit WGM")
        echo $CHOICE
        case "$CHOICE" in
            Settings)
                display_settings
                ;;
            Configure)
                YN=$(wt --title "Update Settings"\
                   --yesno "WARNING: this mith prevent configured clients (if any) form connecting. Are you sure you want to continue?" \
                   --defaultno\
                    8 80
                )
                if [[ "$?" == 0 ]]; then
                    create_settings
                fi
                ;;
            Status)
                show_status
                ;;
            Start)
                wg-quick up wg0
                show_updown
                ;;
            Stop)
                wg-quick down wg0
                show_updown
                ;;
            Install)
                install_wg
                ;;

            ListUsers)
                listusers
                ;;
            AddUsers)
                add_client
                ;;
            RemoveUser)
                removeusers
                ;;
            RemoveVPN)
                uninstall_wg
                ;;
            Exit)
                exit 0
                ;;
            *)      
                exit 1
                ;;
        esac    
    done
}

###############################################################################
# Checks

# Check whiptail installed
if ! check_whiptail; then
    exit 1
fi

# Check this is run by root
if [ "$EUID" -ne 0 ]; then
    wt  --title "Invalid user" \
        --msgbox "This script requires root privileges to run." \
        8 80
    exit 1
fi

# Check that the module is in the kernel
modprobe wireguard
if [[ $? != 0 ]]; then
    echo "Wireguard module is not in the kernel"
    echo "Please refer to documentation on how to install kernel headers and wireguard module"
    wt  --title "Missing Wireguard module" \
        --msgbox "The Linux Kernel you are running does not include the Wireguard module. Please refer to specific documentation on how to install kernel headers and wireguard module" \
        8 80
    exit 1
fi

wt --title "VPN Disclaimer" --msgbox "$DISCLAIMER" --scrolltext  25 70

# Check if previoulsy run/configured
if [ ! -f "$CFG_DIR/settings.conf" ]; then
    # it not, create config file
    install_wg
    create_settings
fi
  
# Load setting and go to menù
main_menu

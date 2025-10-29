# Check this is run by root
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root."
    exit 1
fi

## Save starting dir
IWD=$PWD

## Install requirements
apt-get install - qyy git make gcc


## Install endlessh
cd /opt
git clone https://github.com/skeeto/endlessh.git
cd endlessh
make
make install

## Configuration file
TMP=$(mktemp)
cat > $TMP << EOF
# The port on which to listen for new SSH connections.
Port %%PORT%%

# The endless banner is sent one line at a time. This is the delay
# in milliseconds between individual lines.
Delay 5000

# The length of each line is randomized. This controls the maximum
# length of each line. Shorter lines may keep clients on for longer if
# they give up after a certain number of bytes.
MaxLineLength 32

# Maximum number of connections to accept at a time. Connections beyond
# this are not immediately rejected, but will wait in the queue.
MaxClients 1024

# Set the detail level for the log.
#   0 = Quiet
#   1 = Standard, useful log messages
#   2 = Very noisy debugging information
LogLevel 1

# Set the family of the listening socket
#   0 = Use IPv4 Mapped IPv6 (Both v4 and v6, default)
#   4 = Use IPv4 only
#   6 = Use IPv6 only
BindFamily 0
EOF
cat $TMP | sed "s:%%PORT%%:$ENDLESS_PORT:" > /etc/endlessh/config
rm -f $TMP

## Service
setcap 'cap_net_bind_service=+ep' /usr/local/bin/endlessh
cd $IWD
cp endlessh.service /etc/systemd/system
systemctl daemon-reload
systemctl enable --now endlessh.service

## Final cleanup
apt-get remove gcc make

## Output
echo "Endlessh installed! \
    Now you can: \
    - change the port of regular ssh from 22 to something random \
        - keep 2 connections open while doing this, just in case \
    - change the port of endelssh form 2222 to 22 \
        - modify /etc/endlessh/config Port value
    - monitor connections attempts with journalctl -f"

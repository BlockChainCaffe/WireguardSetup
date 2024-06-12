## Install endlessh


## Install requirements
apt-get install -qyy git make gcc


cd /opt
git clone https://github.com/skeeto/endlessh.git
cd endlessh
make
make install

## Configuration file
cat > /etc/endlessh/config << EOF
# The port on which to listen for new SSH connections.
Port 2222

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

## Service
cp util/endlessh.service /etc/systemd/system
systemctl daemon-reload
systemctl enable --now endlessh.service

## Final cleanup
apt-get remove gcc make

## Output
echo "Endlessh installed! \
    Now you can: \
    - change the port of regular ssh from 22 to something random \
    - change the port of endelssh form 2222 to 22 \
        (follow instructions on endlessh.service file)
    - monitor connections attempts with journalctl -f"

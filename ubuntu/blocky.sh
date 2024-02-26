
## Move configuration file in blocky work directory
mkdir /opt/blocky
cp blocky.yml /opt/blocky/blocky_config.yml


## Download latest release and move binary to /opt/blocky
cd /opt/blocky
TGZ=$(curl -s https://api.github.com/repos/0xERR0R/blocky/releases/latest | grep "browser_download_url" | grep Linux | grep $(uname -m) | cut -d':' -f 2,3 | tr -d '"')
wget $TGZ
tar -zxf *.tar.gz 2>/dev/null
tar -zxf *.tgz 2>/dev/null
find . -type f -name blocky -exec mv {} /opt/blocky/. \;
rm *gz


# Allow to bind to port < 1024
setcap cap_net_bind_service=ep /opt/blocky/blocky


## Start as a service
cat > /etc/systemd/system/blocky.service <<_EOF_
[Unit]
Description=Blocky is a DNS proxy and ad-blocker
ConditionPathExists=/opt/blocky
After=local-fs.target

[Service]
DynamicUser=yes
PrivateTmp=true
PrivateDevices=true
ProtectSystem=full
ProtectHome=true
InaccessiblePaths=/run /var

Type=simple
WorkingDirectory=/opt/blocky
ExecStart=/opt/blocky/blocky --config /opt/blocky/blocky_config.yml
Restart=on-failure
RestartSec=10

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=blocky

[Install]
WantedBy=multi-user.target
_EOF_

systemctl daemon-reload
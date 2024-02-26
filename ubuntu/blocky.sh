

## Download latest release and move binary to /opt/blocky
cd /opt
mkdir /opt/blocky
cd /opt/blocky
TGZ = $(curl -s https://api.github.com/repos/0xERR0R/blocky/releases/latest | grep "browser_download_url" | grep Linux | grep $(uname -m) | cut -d':' -f 2,3)
wget $TGZ
tar -zxf *.tar.gz
tar -zxf *.tgz
find . -type f -name blocky -exec mv {} /opt/blocky/. \;
rm *gz

## Configuration file


## Start as a service

# Allow to bind to port < 1024
setcap cap_net_bind_service=ep /opt/blocky/blocky

cat > $/etc/systemd/system/blocky.service <<_EOF_
[Unit]
Description=Blocky is a DNS proxy and ad-blocker
ConditionPathExists=/opt/blocky
After=local-fs.target

[Service]
User=nobody
Group=nobody
Type=simple
WorkingDirectory=/opt/blocky
ExecStart=/opt/blocky/blocky --config /opt/blocky/config.yml
Restart=on-failure
RestartSec=10

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=blocky

[Install]
WantedBy=multi-user.target
_EOF_

systemctl daemon-reload
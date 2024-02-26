# Wireguard Setup Scripts

Yet another set of scripts to setup a self hosted VPN with
- **blocky** as filtering DNS server
- **wireguard** as VPN
- **endlessh** as sshd honeypot
- **tor** the onion router

### General assumptions:
- you have a VPS
- you can handle a Linux system
- scripts will be run by root
- scripts will not do all for you...
- these scripts work mostly with **IPV4** internet addresses


## 1) Endlessh setup
Endlessh is an SSH tarpit. It basically uses a reverse "slow-loris attack" on bots trying to
connect to your ssh service. Bots might get stuck for a long time and then give up. It's more
fun than fail2ban as this will waste attacker time and protect other servers in the meantime
More info at https://github.com/skeeto/endlessh

What to do:
- change the listening port of your ssh server
- beware not to lock yourself out of the server: keep 2 connections open as a failsafe
- run the install script
- run endlessh on port 22
- try to connect to server and see the results:
```
$ ssh -vvv root@<server>
OpenSSH_8.9p1 Ubuntu-3ubuntu0.6, OpenSSL 3.0.2 15 Mar 2022
debug1: Reading configuration data /etc/ssh/ssh_config
...
debug1: Connecting to 208.94.39.137 [208.94.39.137] port 22.
debug1: Connection established.
...
debug1: Local version string SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6
debug1: kex_exchange_identification: banner line 0: eFkS)@              ## ...long time...
debug1: kex_exchange_identification: banner line 1: q|Y:>v3T1C5+4       ## ...long time...
debug1: kex_exchange_identification: banner line 2: 2sz3}0Jm,;$N}^k     ## ...long time...
```

### Configuration
Configuration file is at `/etc/endlessh/config`

### Start and stop
Use the `endlessh.service` daemon for systemd
```
systemctl start endlessh.service
systemctl stop endlessh.service
systemctl status endlessh.service
```

### Logs
```
journalctl -f | grep endlessh
```

## 2) Blocky setup
Blocky is a DNS proxy and ad-blocker (similar to Pi-Hole) for the local network written in Go with following features:
- Blocking of DNS queries with external lists (Ad-block, malware)
- Advanced DNS configuration
- Performance
- Various Protocols
- Security and Privacy
- Integration
- Prometheus metrics
- Simple installation/configuration
- Stateless (no database, no temporary files)
- Single binary

More info at https://0xerr0r.github.io/blocky/v0.23/

### Configuration
Blocky work directory is `/opt/blocky`
Configuration file is at `/opt/blocky/blocky_config.yml`

### Start and stop
Use the `blocky.service` daemon for systemd
```
systemctl start blocky.service 
systemctl stop blocky.service 
systemctl status blocky.service 
```

### Logs
```
journalctl -f | grep blocky
```


## 3) Wireguard Setup
WireGuard is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec, while avoiding the massive headache. 

Main site:
  - https://www.wireguard.com/

Unofficial Documentation:
  - https://github.com/pirate/wireguard-docs?tab=readme-ov-file

### Assumptions
- kernel contains wireguard module
- server configuration file il always **/etc/wireguard/wg0**
- server keys and client configuration will be stored in the folder /root/Wireguard


## Usage

### Server setup
- edit the `settings.sh` file to set your configuration
  - the only thing you should need to do is specify a DNS name for the server, if your server has one
- run the `settings.sh` script and see if results are fine
```
bash -x settings.sh
```
- run the server setup script
- check that interface wg0 is up and running with:

```bash
ip a

7: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none 
    inet 10.20.0.1/24 scope global wg0
       valid_lft forever preferred_lft forever

```
- check the VPN status with:
```
$ wg
interface: wg0
  public key: PqgP................................hAx6B3g=
  private key: (hidden)
  listening port: 33223

```

Once the server is up, configure the clients

### PC Client setup

- pick a name for the client
- run a client_add.sh script 
```bash
bash client_add.sh <client name>  # one word, no spaces, puntuation etc
```
- the script will produce files in `/root/Wireguard/clients` folder
- export the produced .tgz file to the client
- the .tgz file will containt 4 files
  - privatekey : self explanatory
  - publickey : self explanatory
  - wg0.conf : configuration file to access the VPN and other nodes in the VPN
  - **wg0A.conf** : configuration to route **ALL TRAFFIC** via VPN and that will use **blocky** as DNS
- copy the configuration files in /etc/wireguard
- start the client with
```bash 
wg-quick up <configuration file> # omit '.conf'
```
- stop the client with
```bash
wg-quick down <configuration file> # omit '.conf'
```

## 4) TOR setup
(tbd)
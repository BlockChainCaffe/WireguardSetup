# Wireguard Setup Scripts

Yet another set of scripts to setup a self hosted Wireguard VPN

## Assumptions
- scripts will be run by root
- kernel contains wireguard module
- these scripts work with **IPV4** internet addresses
- server configuration file il always **/etc/wireguard/wg0**
- server keys and client configuration will be stored in the folder /root/Wireguard


## Usage

### Server setup
- clone the repo
- edit the settings.sh file to set your configuration
  - the only thing you should need to do is specify a DNS name, if your server has one
- run the server setup script
- check that interface wg0 is up and running with:

```bash
ip a
```

### Client setup

- run a client_add.sh script 
```bash
bash client_add.sh <client name>  # one word, no spaces, puntuation etc
```
- export the produced .tgz file to the client
- the .tgz file will containt
  - privatekey and publickey : self explanatory
  - wg0.conf : configuration file to access the VPN
  - wg0A.conf : configuration to route **ALL TRAFFIC** via VPN
- copy the configuration files in /etc/wireguard
- start the client with
```bash 
wg-quick up <configuration file> # omit '.conf'
```
- stop the client with
```bash
wg-quick down <configuration file> # omit '.conf'
```


# Links

Unofficial Documentation 
  - https://github.com/pirate/wireguard-docs?tab=readme-ov-file
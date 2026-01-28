# VPN-Server-Setup

Project: https://roadmap.sh/projects/vpn-server-setup

## Wireguard Installation
1. Install Wireguard
```bash
sudo apt update
sudo apt install wireguard -y

wg --version
```

2. Generate serever's keys
```bash
sudo umask 077
mkdir -p wireguard
cd wireguard
wg genkey | tee server_private.key | wg pubkey > server_public.key
```

3. Server configuration
```bash
sudo nano /etc/wireguard/wg0.conf
Add:

[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = <SERVER_PRIVATE_KEY>

# NAT
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

4. Turn on IP forwarding
```bash
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf 
sudo sysctl -p
sysctl net.ipv4.ip_forward # check
```

5. Open port WireGuard в firewall (iptables)
```bash
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -L INPUT -n # check
```

6. Start WireGuard
```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

sudo wg
ip a show wg0
```

7. Connecting client
```bash
nano add_user_script.sh

CLIENT=n.uzumaki # Set client name  
IP=10.10.0.4 # Set ip from mask 10.10.0.2/24, ip 10.10.0.1/32 this interface wgo our vpn server

mkdir -p /root/wireguard/${CLIENT} # where will be stored .conf pubkey and secret_key your user
```

## OpenVPN Installation
1. Infrastructure preparation PKI (Easy-RSA)
```bash
sudo apt update && sudo apt install openvpn easy-rsa -y
mkdir ~/openvpn-ca && cd ~/openvpn-ca
ln -s /usr/share/easy-rsa/* .
chmod 700 ~/openvpn-ca

# Initialize and create CA(without pass)
./easyrsa init-pki
./easyrsa build-ca nopass

# Generate server's certs
# Create request and sing it
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate Diffie-Hellman (required for key exchange), needs if your openvpn < 2.4
./easyrsa gen-dh

# for TLS security
openvpn --genkey secret ta.key
```

2. Server Configuration
```bash
cp pki/ca.crt pki/issued/server.crt pki/private/server.key ta.key /etc/openvpn/server/
# cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem ta.key /etc/openvpn/server/ 

sudo nano /etc/openvpn/server/server.conf

# File path
# ----
port 1194
proto udp
dev tun

ca ca.crt
cert server.crt
key server.key
dh none
tls-crypt ta.key

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
# if you install Pi-hole
#push "dhcp-option DNS 10.8.0.1" 

keepalive 10 120

cipher AES-256-GCM
data-ciphers AES-256-GCM:AES-128-GCM

persist-key
persist-tun

verb 3
# ----
```

3. Setup Settings(Forwarding & Firewall)
```bash
# Enable IP Forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf && sudo sysctl -p

# NAT - MASQUERADE for OpenVPN traffic (eth0 - your main network interface with public IP)
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# FORWARD rules for OpenVPN (tun0 - interface created by OpenVPN)
# Allow traffic from VPN clients to internet
sudo iptables -A FORWARD -i tun0 -o eth0 -s 10.8.0.0/24 -j ACCEPT

# Allow return traffic from internet to VPN clients
sudo iptables -A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow established connections (can be combined with above, but keeping separate for clarity)
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# INPUT rules
# Allow OpenVPN port
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# Allow DNS queries from VPN clients (if using Pi-hole or local DNS)
sudo iptables -A INPUT -i tun0 -p udp --dport 53 -j ACCEPT
sudo iptables -A INPUT -i tun0 -p tcp --dport 53 -j ACCEPT

# Save iptables rules permanently
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

4. Start
```bash
sudo systemctl enable openvpn-server@server
sudo systemctl restart openvpn-server@server
```

## Pi-hole install
1. Install
```bash
curl -sSL https://install.pi-hole.net | bash
```
During installation (Installer Steps):
  - Interface: Select basic (eth0)
  - Upstream DNS: Select Google (8.8.8.8) or Cloudflare (1.1.1.1)
  - Blocklists: Agree to the default list (StevenBlack's list)
  - Web Interface: Be sure to put it Yes (On)

2. Password
At the end of the installation you will be shown a password. If you missed it or want to change it:
```bash
pihole -a setpassword
```

3. Config file
```bash
nano /etc/pihole/pihole.toml
[dns]
listeningMode = "ALL"
interface=""

pihole reloaddns
sudo systemctl restart pihole-FTL
sudo systemctl status pihole-FTL
```

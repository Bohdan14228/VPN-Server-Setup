# VPN-Server-Setup

Project: https://roadmap.sh/projects/vpn-server-setup

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


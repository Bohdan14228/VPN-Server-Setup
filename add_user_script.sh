#!/bin/bash

CLIENT=n.uzumaki
IP=10.10.0.4

mkdir -p /root/wireguard/${CLIENT} 
wg genkey | tee /root/wireguard/${CLIENT}/${CLIENT}_priv.key | wg pubkey > /root/wireguard/${CLIENT}/${CLIENT}_pub.key

cat > /root/wireguard/${CLIENT}/${CLIENT}.conf <<EOF
[Interface]
PrivateKey = $(cat /root/wireguard/${CLIENT}/${CLIENT}_priv.key)
Address = ${IP}/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /root/wireguard/server_public.key)
Endpoint = 46.101.254.171:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

wg set wg0 peer $(cat /root/wireguard/${CLIENT}/${CLIENT}_pub.key) allowed-ips ${IP}/32
wg-quick save wg0
wg show

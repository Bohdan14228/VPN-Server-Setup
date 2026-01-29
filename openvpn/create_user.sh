#!/bin/bash
CLIENT=$1

./easyrsa --batch gen-req "$CLIENT" nopass >/dev/null 2>&1
./easyrsa --batch sign-req client "$CLIENT" >/dev/null 2>&1

mkdir -p users_ovpn
cat > ./users_ovpn/${CLIENT}.ovpn << EOF
client
dev tun
proto udp

remote 46.101.254.171 1194
resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server

cipher AES-256-GCM
data-ciphers AES-256-GCM:AES-128-GCM

verb 3

<tls-crypt>
$(sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' ./ta.key)
</tls-crypt>

<ca>
$(cat ./pki/ca.crt)
</ca>

<cert>
$(sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' ./pki/issued/${CLIENT}.crt)
</cert>

<key>
$(cat ./pki/private/${CLIENT}.key)
</key>
EOF

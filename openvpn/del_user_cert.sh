#!/bin/bash

CLIENT=$1

# Отозвать сертификат
./easyrsa --batch revoke "$CLIENT" >/dev/null 2>&1

# Сгенерировать CRL (Certificate Revocation List)
./easyrsa --batch gen-crl >/dev/null 2>&1

# Скопировать CRL в OpenVPN (чтобы сервер знал об отозванных сертификатах)
sudo cp ~/openvpn-ca/pki/crl.pem /etc/openvpn/server/

# Удалить файлы пользователя
rm -f ~/openvpn-ca/pki/reqs/${CLIENT}.req
rm -f ~/openvpn-ca/pki/private/${CLIENT}.key
rm -f ~/openvpn-ca/pki/issued/${CLIENT}.crt
rm -f ~/openvpn-ca/users_ovpn/${CLIENT}.ovpn

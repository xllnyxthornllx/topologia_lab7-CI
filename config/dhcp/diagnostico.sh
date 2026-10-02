#!/bin/bash
# Diagnostico Lab07 - correr en 192.168.45.128 (usuario nyxthorn)
# Uso: chmod +x diagnostico.sh && ./diagnostico.sh
set -u
echo "===== OS ====="
cat /etc/os-release 2>/dev/null || lsb_release -a 2>/dev/null || uname -a
echo
echo "===== KERNEL/HOST ====="
uname -a; hostname; whoami
echo
echo "===== INTERFACES ====="
ip -brief addr show
echo
ip route show
echo
echo "===== DNS ====="
cat /etc/resolv.conf
echo
echo "===== DHCP YA INSTALADO? ====="
which kea-dhcp4 kea-dhcp4-server dnsmasq dhcpd isc-dhcp-server 2>/dev/null
dpkg -l 2>/dev/null | grep -Ei 'kea|dnsmasq|isc-dhcp|dhcp' | head -20
rpm -qa 2>/dev/null | grep -Ei 'kea|dnsmasq|dhcp' | head -20
systemctl list-units 2>/dev/null | grep -Ei 'kea|dnsmasq|dhcp' | head -20
echo
echo "===== PUERTOS 67/68 ====="
(ss -lunp 2>/dev/null || netstat -lunp 2>/dev/null) | grep -E ':67|:68' || echo "nada escuchando en 67/68"
echo
echo "===== COPIA ESTA SALIDA Y PASASELA AL ASISTENTE ====="

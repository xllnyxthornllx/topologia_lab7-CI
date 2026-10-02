#!/bin/bash
# verificar-lab.sh - chequeo post-config, correr EN LA VM ya en lab
# Uso: chmod +x verificar-lab.sh && ./verificar-lab.sh
set -u
echo "===== IP/RUTAS ====="
ip -brief addr show
ip route show
echo
echo "===== DNS ====="
cat /etc/resolv.conf
echo
echo "===== DNSMASQ ====="
systemctl is-active dnsmasq
cat /etc/dnsmasq.d/lab07.conf
echo "--- leases ---"
cat /var/lib/misc/dnsmasq.leases 2>/dev/null || echo "(sin leases aun)"
echo
echo "===== PING GATEWAYS ====="
ping -c 3 -W 2 172.18.99.1 || echo "FAIL GW99"
ping -c 3 -W 2 172.18.30.1 || echo "FAIL GW30 (normal si router aun no configura relay)"
echo
echo "===== PUERTO 67 ====="
(ss -lunp 2>/dev/null | grep ':67') || echo "no escucha en 67"

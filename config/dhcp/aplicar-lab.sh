#!/bin/bash
# aplicar-lab.sh - correr EN LA VM cuando ya este pinchada al puerto VLAN 99 (Gi1/0/10)
# Uso: chmod +x aplicar-lab.sh && sudo ./aplicar-lab.sh
set -e
echo "[1/4] Respaldando netplan actual..."
mkdir -p ~/netplan-backup
cp -a /etc/netplan/*.yaml ~/netplan-backup/ 2>/dev/null || true
ls ~/netplan-backup/

echo "[2/4] Instalando dnsmasq si falta..."
if ! command -v dnsmasq >/dev/null; then
  apt-get update && apt-get install -y dnsmasq iproute2
fi

echo "[3/4] Aplicando IP 172.18.99.10/24..."
cp ./50-lab07.yaml /etc/netplan/50-lab07.yaml
# Desactiva otros yamls que den DHCP a ens33 para evitar conflicto:
for f in /etc/netplan/*.yaml; do
  [ "$f" = "/etc/netplan/50-lab07.yaml" ] && continue
  echo "  Revisa $f (renombralo a .bak si da DHCP a ens33)"
done
netplan apply
sleep 3
ip -brief addr show ens33
ip route show default

echo "[4/4] Instalando config DHCP lab..."
mkdir -p /etc/dnsmasq.d
cp ./dnsmasq.conf /etc/dnsmasq.d/lab07.conf
systemctl enable dnsmasq || true
systemctl restart dnsmasq
systemctl status dnsmasq --no-pager -l | head -25 || true
ss -lunp | grep ':67' || echo "WARN: no escucha en 67, revisa journalctl -u dnsmasq"
echo
echo "OK. Valida desde PC Admin: ipconfig /renew + ping 172.18.99.1"

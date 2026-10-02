#!/bin/bash
# Setup DHCP Lab07 con dnsmasq (rapido) - correr en 192.168.45.128
# Uso: chmod +x setup-dhcp.sh && sudo ./setup-dhcp.sh
# Deja IP 172.18.99.10/24 + pools GESTION y CCTV + reservas ejemplo.
set -e
IFACE="${IFACE:-ens33}"
SERVER_IP="172.18.99.10/24"
GW="172.18.99.1"

echo "[1/5] Instalando dnsmasq..."
if command -v apt-get >/dev/null; then
  apt-get update && apt-get install -y dnsmasq iproute2
elif command -v dnf >/dev/null; then
  dnf install -y dnsmasq iproute2
elif command -v yum >/dev/null; then
  yum install -y dnsmasq iproute2
else
  echo "Gestor de paquetes no soportado. Instala dnsmasq manual."; exit 1
fi

echo "[2/5] Configurando IP estatica temporal en $IFACE..."
ip addr flush dev "$IFACE" || true
ip addr add "$SERVER_IP" dev "$IFACE" || echo "IP ya asignada o error, revisa con: ip addr show $IFACE"
ip link set "$IFACE" up
ip route replace default via "$GW" dev "$IFACE" || true

echo "[3/5] Escribiendo /etc/dnsmasq.d/lab07.conf..."
mkdir -p /etc/dnsmasq.d
cp "$(dirname "$0")/dnsmasq.conf" /etc/dnsmasq.d/lab07.conf
echo "--- contenido instalado ---"
cat /etc/dnsmasq.d/lab07.conf

echo "[4/5] Reiniciando dnsmasq..."
systemctl enable dnsmasq || true
systemctl restart dnsmasq
systemctl status dnsmasq --no-pager -l | head -30 || true

echo "[5/5] Verificacion..."
ip -brief addr show "$IFACE"
ip route show default
(ss -lunp | grep ':67') || echo "WARN: dnsmasq no escucha en 67, revisa journalctl -u dnsmasq"
echo
echo "OK. Ahora edita reservas MAC reales en /etc/dnsmasq.d/lab07.conf y haz: systemctl restart dnsmasq"
echo "Valida desde PC Admin: ipconfig /renew && ping 172.18.99.1 && ping 172.18.30.10"

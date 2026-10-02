# Acceso SSH a C9300L + C9200L - Lab 07

## 1. Clave (CÁMBIALA antes de pegar configs)
En ambos configs viene: `username netadmin privilege 15 secret Lab07*Admin` + `enable secret Lab07*Admin`
- Cambia `Lab07*Admin` por tu clave real en AMBOS equipos (busca y reemplaza, sale 2 veces por archivo).
- El `crypto key generate rsa modulus 2048` ya va FUERA del bloque `configure terminal` (es comando de modo enable, pegado tal cual funciona).

## 2. IPs de gestión (XX=18 por defecto)
| Equipo | IP SSH | GW | Notas |
|--------|--------|-----|-------|
| C9300L (core L3) | 172.18.99.1 y 172.18.30.1 (ambas entran) | — (él es el GW) | `ip routing` activo |
| C9200L (acceso) | 172.18.99.2 | 172.18.99.1 | SVI Vlan99 + `ip default-gateway` |
| VM DHCP | 172.18.99.10 (en lab) / 192.168.45.128 (ahora) | 172.18.99.1 en lab | SSH con llave ya funciona |

## 3. Conectarse desde PC Admin (VLAN 99)
```powershell
ssh netadmin@172.18.99.1   # C9300L
ssh netadmin@172.18.99.2   # C9200L
```
En PuTTY: Host Name = IP, Port 22, Connection type SSH.

## 4. Para que YO te ayude a revisar
Cuando estén en red, pásame:
1. Salida de en cada equipo:
```
show running-config | include username|domain|vlan|helper|default-gateway
show vlan brief
show ip interface brief
show interfaces trunk
show ssh
```
2. En C9300L además: `show ip route connected` y `show ip helper-address`
3. Tu clave NO me la pases por chat del lab; si quieres que entre yo, crea un usuario temporal y lo borras después:
```
configure terminal
username ayudante privilege 15 secret ClaveTemporal123*
end
write memory
```

## 5. Si SSH dice "Connection refused"
- Verifica `show ip interface brief` → Vlan99/30 en `up/up`
- Verifica `show ssh` → debe decir version 2.0 enabled
- Verifica `line vty 0 15` tenga `transport input ssh` + `login local`
- Regenera llave: `crypto key generate rsa modulus 2048` (confirma reemplazo)
- Desde el propio switch: `ssh -l netadmin 172.18.99.2` (prueba local)

## 6. Orden de configuración sugerido
1. C9300L: VLANs → SVIs → `ip routing` → uplink trunk → SSH → `write memory`
2. C9200L: VLANs → access ports → uplink trunk → SVI mgmt + GW → SSH → `write memory`
3. Conecta cable uplink 9300L ↔ 9200L → `show interfaces trunk` en ambos debe mostrar 30,99
4. Recién ahí pincha VM DHCP a Gi1/0/24 del 9200L y corre `sudo ./aplicar-lab.sh`

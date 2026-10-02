# Lab 07 — Red de Videovigilancia IP Hikvision

**Curso:** R66325 — Comunicación Inalámbrica  
**Laboratorio:** N° 07  
**Fecha:** 2026-02  
**Alumno:** J. Álvarez  
**Repo:** `git@github.com:xllnyxthornllx/topologia_lab7-CI.git`  
**Sitio (Netlify):** https://topologia-lab7-ci.netlify.app (tras deploy)

---

## 1. Objetivos

- Implementar red segmentada: **VLAN 30 CCTV** + **VLAN 99 Gestión**
- Configurar **NVR Hikvision** con HDD 1 TB + 2 cámaras:
  - Cámara 1 → Switch C9200L (puerto Gi1/0/2, access VLAN 30, PoE)
  - Cámara 2 → Puerto PoE directo del NVR (red interna, Plug&Play)
- Gestionar desde **PC Admin** (VLAN 99) con **iVMS-4200** + **HiTools Delivery**
- **PC Monitoreo** (VLAN 30, Gi1/0/4) → vista directa a Cámara 1 sin router
- Configurar **detección de movimiento** + grabación por evento (Lun–Sáb)
- Validar: direccionamiento, conectividad, Live View, reproducción, eventos, almacenamiento

---

## 2. Topología — Mapa de puertos

| Equipo | Puerto | Conexión | VLAN / Red | Modo |
|--------|--------|----------|------------|------|
| **C9300L (Core L3)** | Gi1/0/1 | → C9200L Gi1/0/1 | trunk 30,99 | trunk |
| | Gi1/0/24 | → Proveedor Internet | routed DHCP (WAN) | no switchport |
| | Vlan30 | GW CCTV | 172.18.30.1/24 | SVI + helper |
| | Vlan99 | GW Gestión | 172.18.99.1/24 | SVI |
| **C9200L (Acceso)** | Gi1/0/1 | → C9300L Gi1/0/1 | trunk 30,99 | trunk |
| | Gi1/0/2 | → Cámara 1 | 30 | access + PoE |
| | Gi1/0/3 | → NVR LAN | 30 | access |
| | Gi1/0/4 | → **PC Monitoreo** | 30 | access |
| | Gi1/0/24 | → **VM DHCP** (ens33) | 99 | access |
| | Gi1/0/10 | → PC Admin | 99 | access |
| **NVR Hikvision** | LAN | → C9200L Gi1/0/3 | 172.18.30.10/24 | estática |
| | PoE-1 | → Cámara 2 | red interna NVR | PoE directo |
| **VM DHCP (nyxthorn)** | ens33 | → C9200L Gi1/0/24 | 172.18.99.10/24 | estática (dnsmasq) |
| **PC Admin** | — | → C9200L Gi1/0/10 | DHCP .100-.180 | cliente |
| **PC Monitoreo** | — | → C9200L Gi1/0/4 | DHCP CCTV .100-.180 | cliente |

---

## 3. Direccionamiento (XX = 18 por defecto, editable en la web)

| Dispositivo | VLAN | IP | Gateway |
|-------------|------|-----|---------|
| C9300L Vlan30 | 30 | 172.18.30.1 | — |
| C9300L Vlan99 | 99 | 172.18.99.1 | — |
| NVR LAN | 30 | 172.18.30.10 | 172.18.30.1 |
| Cámara 1 (switch) | 30 | 172.18.30.20 | 172.18.30.1 |
| Cámara 2 (PoE NVR) | PoE int. | asignada por NVR | — |
| VM DHCP ✅ | 99 | 172.18.99.10 | 172.18.99.1 |
| PC Admin | 99 | DHCP .100-.180 | 172.18.99.1 |
| PC Monitoreo | 30 | DHCP CCTV .100-.180 | 172.18.30.1 |

**Reservas DHCP sugeridas (dnsmasq):**
```
NVR → 172.18.30.10
Cam1 → 172.18.30.20
PC Monitoreo → 172.18.30.30
```

---

## 4. Matriz de accesos

| Estación | Qué ve | Cómo |
|----------|--------|------|
| **PC Monitoreo (VLAN 30)** | Cámara 1 (web directa), NVR (web/iVMS) | Mismo segmento L2 → sin router |
| | Cámara 2 | Solo como canal del NVR (red PoE no ruteada) |
| **PC Admin (VLAN 99)** | NVR + **ambos canales** en iVMS-4200 | Routing inter-VLAN |
| | Cámara 1 | Web/HiTools vía routing |
| | Cámara 2 | Vía NVR en iVMS (Virtual Host opcional) |
| | Switches / DHCP | SSH en VLAN 99 |

---

## 5. Configuraciones listas (copiar-pegar)

### 5.1 C9300L Core L3 — `config/c9300L-core/config.txt`
```cisco
en
configure terminal
hostname C9300L-LAB07
ip domain name lab07.local
no ip domain lookup
vlan 30; name CCTV; exit
vlan 99; name GESTION; exit
ip routing
interface Vlan30; description GW_CCTV; ip address 172.18.30.1 255.255.255.0; ip helper-address 172.18.99.10; no shutdown; exit
interface Vlan99; description GW_GESTION; ip address 172.18.99.1 255.255.255.0; no shutdown; exit
interface GigabitEthernet1/0/1; description UPLINK_SW9200L; switchport mode trunk; switchport trunk allowed vlan 30,99; no shutdown; exit
interface GigabitEthernet1/0/24; description WAN_PROVEEDOR; no switchport; ip address dhcp; no shutdown; exit
username netadmin privilege 15 secret TU_CLAVE
enable secret TU_CLAVE
ip ssh version 2; ip ssh time-out 60; ip ssh authentication-retries 3
line vty 0 15; transport input ssh; login local; exec-timeout 15 0; exit
line console 0; login local; exec-timeout 15 0; exit
service password-encryption
end
crypto key generate rsa modulus 2048
write memory
```

### 5.2 C9200L Acceso — `config/c9200L-acceso/config.txt`
```cisco
en
configure terminal
hostname C9200L-ACCESO
ip domain name lab07.local
no ip domain lookup
vlan 30; name CCTV; exit
vlan 99; name GESTION; exit
interface GigabitEthernet1/0/2; description CAMARA_1_HIKVISION; switchport mode access; switchport access vlan 30; spanning-tree portfast; spanning-tree bpduguard enable; no shutdown; exit
interface GigabitEthernet1/0/3; description NVR_HIKVISION_LAN; switchport mode access; switchport access vlan 30; spanning-tree portfast; spanning-tree bpduguard enable; no shutdown; exit
interface GigabitEthernet1/0/4; description PC_MONITOREO_CCTV; switchport mode access; switchport access vlan 30; spanning-tree portfast; spanning-tree bpduguard enable; no shutdown; exit
interface GigabitEthernet1/0/24; description SERVIDOR_DHCP_ens33; switchport mode access; switchport access vlan 99; spanning-tree portfast; spanning-tree bpduguard enable; no shutdown; exit
interface GigabitEthernet1/0/10; description PC_ADMIN_iVMS; switchport mode access; switchport access vlan 99; spanning-tree portfast; spanning-tree bpduguard enable; no shutdown; exit
interface GigabitEthernet1/0/1; description UPLINK_C9300L; switchport mode trunk; switchport trunk allowed vlan 30,99; no shutdown; exit
interface Vlan99; description MGMT; ip address 172.18.99.2 255.255.255.0; no shutdown; exit
ip default-gateway 172.18.99.1
username netadmin privilege 15 secret TU_CLAVE
enable secret TU_CLAVE
ip ssh version 2; ip ssh time-out 60; ip ssh authentication-retries 3
line vty 0 15; transport input ssh; login local; exec-timeout 15 0; exit
line console 0; login local; exec-timeout 15 0; exit
service password-encryption
end
crypto key generate rsa modulus 2048
write memory
```

> ⚠️ Cambia `TU_CLAVE` por tu clave real en **ambos** antes de pegar.

### 5.3 VM DHCP (dnsmasq) — `config/dhcp/`
```bash
# En la VM (nyxthorn@nyxthorn):
cd ~/lab07
sudo ./aplicar-lab.sh      # pone IP 172.18.99.10/24 + GW .1 + dnsmasq
./verificar-lab.sh         # valida
```
Archivos: `dnsmasq.conf`, `50-lab07.yaml`, `aplicar-lab.sh`, `verificar-lab.sh`

---

## 6. Secuencia de puesta en marcha (orden)

| Paso | Acción | Verificación |
|------|--------|--------------|
| 1 | Cablear todo según mapa de puertos | LEDs link up en puertos |
| 2 | **C9300L**: pegar config completa → `crypto key` → `write mem` | `show vlan brief`, `show ip int brief`, `show ssh` |
| 3 | **C9200L**: pegar config completa → `crypto key` → `write mem` | `show interfaces trunk`, `show ip int brief`, `show ssh` |
| 4 | Conectar uplink Gi1/0/1 ↔ Gi1/0/1 | `show interfaces trunk` en ambos: 30,99 up |
| 5 | **VM DHCP**: pinchar a Gi1/0/24 → `sudo ./aplicar-lab.sh` | `ip -br a show ens33` = 172.18.99.10/24 |
| 6 | PC Admin: `ipconfig /renew` | recibe 172.18.99.x, GW .1 |
| 7 | PC Admin: `ping 172.18.99.1` y `ping 172.18.30.10` | ambos responden |
| 8 | **NVR**: encender → asistente → IP 172.18.30.10/24 GW .1 → HDD Normal → Overwrite ON |
| 9 | **Cámara 1**: HiTools → activar → IP 172.18.30.20 → NVR add por IP | NVR Camera Management: Online |
| 10 | **Cámara 2**: a puerto PoE libre NVR → Plug&Play → NVR add canal | NVR Camera Management: Online |
| 11 | **iVMS-4200** (PC Admin): add NVR 172.18.30.10 → Live View 2 canales | captura ambos canales |
| 12 | **Motion Detection**: mallas en puertas/pasillos → Trigger Recording | prueba cruzar dentro/fuera |
| 13 | **Recording Schedule**: Lun–Sáb 00:00–24:00 Motion | Playback filtra por evento |
| 14 | Evidencias → carpeta `evidencias/<fase>/` | capturas + videos |

---

## 7. Checklist de cableado (9 cables)

| ID | Cable | De → A | Puerto | Verificación |
|----|-------|--------|--------|--------------|
| 0 | CABLE-00 UPLINK | C9300L Gi1/0/1 ↔ C9200L Gi1/0/1 | trunk 30,99 | `show interfaces trunk` |
| 1 | (lógico) | SVIs C9300L + ip routing | Vlan30/.1, Vlan99/.1 | `ping 172.18.30.1` / `172.18.99.1` |
| 2 | CABLE-01 AMARILLO | C9200L Gi1/0/2 → Cámara 1 | access 30 + PoE | LED PoE + HiTools ve IP |
| 3 | CABLE-02 VERDE | C9200L Gi1/0/3 → NVR LAN | access 30 | `ping 172.18.30.10` |
| 4 | CABLE-03 NARANJA | NVR PoE-1 → Cámara 2 | PoE directo | NVR canal Online |
| 5 | CABLE-04 AZUL | C9200L Gi1/0/24 → VM DHCP | access 99 | `./verificar-lab.sh` |
| 6 | CABLE-05 GRIS | C9200L Gi1/0/10 → PC Admin | access 99 | `ipconfig /renew` |
| 7 | CABLE-06 ROJO | Proveedor → C9300L Gi1/0/24 | WAN routed DHCP | `show ip int brief Gi1/0/24` |
| 8 | CABLE-07 BLANCO | C9200L Gi1/0/4 → PC Monitoreo | access 30 | `ipconfig /renew` → 172.18.30.x |

> En la web (Netlify) cada ✔ se sincroniza en tiempo real con Firebase (ver **checks/check-00**…**check-08**).

---

## 8. Evidencias requeridas

```
evidencias/
├── dhcp/           # ipconfig /renew + leases dnsmasq
├── conectividad/   # ping GW + ping NVR inter-VLAN
├── liveview/       # iVMS ambos canales + NVR Online
├── motion/         # evento dentro malla + clip
├── storage/        # HDD Normal 1 TB
└── playback/       # reproducción por evento
```

Nombrar: `YYYYMMDD_fase_descripcion.png`

---

## 9. Análisis de almacenamiento (pendiente completar)

| Parámetro | Cam 1 | Cam 2 | Total |
|-----------|-------|-------|-------|
| Bitrate configurado | | | |
| % tiempo con movimiento | | | |
| GB/día estimados | | | |
| Días retención (1 TB) | | | |

Fórmula: `GB/día ≈ bitrate_total (Mbps) × 10.8 × fracción_actividad`

---

## 10. Preguntas de análisis (sección 9 del doc original)

1. ¿Ventaja de separar CCTV y gestión en VLANs?
2. ¿Por qué Cámara 2 en PoE NVR no alcanza desde VLAN CCTV?
3. Diferencia: ver canal vía NVR vs web directa de cámara.
4. ¿Cómo afecta sensibilidad a falsas alarmas?
5. ¿Qué zonas excluir en cámara a estacionamiento?
6. Impacto grabación por movimiento vs continua en disco.
7. ¿Por qué IP fija/reserva DHCP en NVR y cámaras?
8. Riesgos si cámaras accesibles desde Internet.

---

## 11. Recursos y enlaces

- **Web interactiva (Netlify):** https://topologia-lab7-ci.netlify.app
  - Topología SVG clicable + checklist sincronizado (Firebase)
  - Generador de configs con XX + clave
  - Matriz de accesos + mapa de puertos
- **Configs locales:** `config/c9300L-core/`, `config/c9200L-acceso/`, `config/dhcp/`
- **Documento original:** `GLAB-S07-JALVAREZ-2026-02-Configuración de red de videovigilancia inalámbrica.docx`
- **Software oficial:** iVMS-4200 / HiTools Delivery (solo portal Hikvision)

---

## 12. Comandos rápidos de verificación

```bash
# C9300L
show vlan brief
show ip interface brief | include Vlan
show ip route connected
show ip helper-address
show ssh

# C9200L
show vlan brief
show interfaces status | include 1/0/
show interfaces trunk
show ip interface brief | include Vlan99
ping 172.18.99.1
ping 172.18.99.10

# VM DHCP
./verificar-lab.sh
cat /var/lib/misc/dnsmasq.leases

# PC Admin
ipconfig /renew
ping 172.18.99.1
ping 172.18.30.10
```

---

## 13. Estado actual (checklist macro)

- [x] Repo GitHub + Netlify deploy
- [x] Topología web interactiva + sync grupal
- [x] Configs C9300L / C9200L / DHCP listas
- [x] Matriz de accesos documentada
- [ ] Cableado físico en lab
- [ ] Configs pegadas en equipos
- [ ] VM DHCP pinchada a Gi1/0/24 + `aplicar-lab.sh`
- [ ] NVR inicializado + HDD
- [ ] Cámaras dadas de alta
- [ ] iVMS-4200 con 2 canales
- [ ] Motion + grabación por evento
- [ ] Evidencias + análisis + informe final

---

*Generado automáticamente desde el repo `topologia_lab7-CI` — Rama `main` — Último commit `4e0ea8d`*
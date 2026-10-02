# Laboratorio 07 - Configuración de red de videovigilancia IP Hikvision

## Información General
- **Curso:** R66325 - Comunicación Inalámbrica
- **Laboratorio:** N° 07
- **Alumno:** J. Álvarez
- **Fecha:** 2026-02
- **Documento original:** `GLAB-S07-JALVAREZ-2026-02-Configuración de red de videovigilancia inalámbrica.docx`

## Objetivo
Implementar una red de videovigilancia IP segmentada mediante VLANs (CCTV y Gestión), configurar NVR Hikvision con 2 cámaras (switch + PoE directo), gestionar desde iVMS-4200, y validar detección de movimiento con grabación por evento.

## Estructura del Proyecto
```
lab7/
├── GLAB-S07-...docx   # Documento original del laboratorio
├── plan.md            # Plan detallado por fases
├── topology.mmd       # Diagrama de topología (Mermaid)
├── index.md           # Este archivo
├── evidencias/        # Capturas por fase
│   ├── dhcp/
│   ├── conectividad/
│   ├── liveview/
│   ├── motion/
│   ├── storage/
│   └── playback/
└── config/            # Configs listas para copiar/pegar
    ├── c9300L-core/config.txt      # Core L3: SVIs + WAN + SSH
    ├── c9200L-acceso/config.txt   # Acceso: puertos + mgmt + SSH
    ├── ssh-guia.md                # Guía acceso SSH
    └── dhcp/                      # Servidor DHCP (dnsmasq listo)
```

## Topología Resumen
Ver `topology.mmd` para diagrama completo (compatible con Mermaid Live, VS Code, GitHub, Obsidian).

| VLAN | Nombre | Red | Gateway | Uso |
|------|--------|-----|---------|-----|
| 30 | CCTV | 172.18.30.0/24 | 172.18.30.1 | NVR .10, Cámara 1 .20 |
| 99 | GESTION | 172.18.99.0/24 | 172.18.99.1 | DHCP .10, PC Admin DHCP |

- **Cámara 2:** red PoE interna del NVR (Plug-and-Play, IP asignada por NVR). Se gestiona como canal del NVR. Para acceso web directo usar Virtual Host si el modelo lo soporta.
- **DHCP Relay:** `ip helper-address 172.18.99.10` en subinterfaz G0/0.30 del router.

## Software Requerido (solo portal oficial Hikvision)
- **iVMS-4200:** Hikvision Global → Software / iVMS-4200 — agregar NVR, Live View, Playback, eventos.
- **HiTools Delivery:** Hikvision Global → HiTools Delivery — descubrir equipos, estado, IP (reemplaza SADP).

## Checklist de Fases
| Fase | Descripción | Estado |
|------|-------------|--------|
| 1 | Inventario y cableado | Pendiente |
| 2 | Switch C9200L: VLANs + puertos - ver config/c9200L-acceso/config.txt | Pendiente |
| 3 | Core C9300L: SVIs + helper + WAN - ver config/c9300L-core/config.txt | Pendiente |
| 4 | DHCP Server (192.168.45.128) | En curso - TU TAREA |
| 5 | NVR: Inicialización + HDD 1TB | Pendiente |
| 6 | Cámara 1 (via Switch) | Pendiente |
| 7 | Cámara 2 (NVR PoE directo) | Pendiente |
| 8 | iVMS-4200 + Live View 2 canales | Pendiente |
| 9 | Motion Detection + mallas | Pendiente |
| 10 | Recording Schedule Lun-Sáb Motion | Pendiente |
| 11 | Pruebas + Evidencias | Pendiente |
| 12 | Análisis almacenamiento | Pendiente |
| 13 | Preguntas análisis | Pendiente |
| 14 | Documentación final | Pendiente |

## Tu Tarea Actual: Fase 4 - Servidor DHCP

Máquina: `192.168.45.128` / usuario `nyxthorn` (vacía, por configurar).

### Objetivo final de red en esa máquina
```
IP estática: 172.18.99.10/24
Gateway: 172.18.99.1
DNS: según laboratorio / 8.8.8.8 temporal
```

### Ámbitos
**GESTION (obligatorio)**
- Red 172.18.99.0/24, pool 172.18.99.100-180, GW 172.18.99.1, lease 8d

**CCTV (opcional, para descubrimiento inicial)**
- Red 172.18.30.0/24, pool 172.18.30.100-180, GW 172.18.30.1
- Reservas: NVR → 172.18.30.10, Cámara 1 → 172.18.30.20

Tienes 3 opciones listas en `config/dhcp/`:
1. `kea-dhcp4.conf` — Kea DHCP moderno (Ubuntu/Debian recomendado)
2. `dnsmasq.conf` — liviano, 1 archivo, ideal para lab rápido
3. `windows-server-guia.md` — si tu VM es Windows Server (GUI + PowerShell)

### Validación
```cmd
:: En PC Admin VLAN 99
ipconfig /renew
ipconfig /all
ping 172.18.99.1
ping 172.18.30.10
```

Evidencias: `ipconfig /all`, leases del servidor, captura ping.

## Preguntas de Análisis (Sección 9 del doc)
1. ¿Qué ventaja aporta separar CCTV y gestión en VLANs diferentes?
2. ¿Por qué la Cámara 2 en PoE del NVR puede no ser alcanzable desde VLAN CCTV?
3. ¿Qué diferencia hay entre visualizar canal vía NVR vs acceso directo a web de cámara?
4. ¿Cómo afecta sensibilidad de detección a falsas alarmas?
5. ¿Qué zonas excluirías en cámara a estacionamiento y por qué?
6. ¿Impacto de grabación por movimiento vs continua en vida útil y capacidad del disco?
7. ¿Por qué IP fija o reserva DHCP en NVR y cámaras?
8. ¿Riesgos si cámaras accesibles directamente desde Internet?

## Evidencias
Guarda capturas en `evidencias/<fase>/` con formato `YYYYMMDD_descripcion.png`.
Checklist completo en `plan.md` Fase 11.

## Referencias
- `plan.md` — plan detallado
- `topology.mmd` — diagrama
- Documento `.docx` original en esta carpeta
- Hikvision NVR User Manual / Motion Detection / Recording Schedule

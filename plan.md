# Plan de Implementación - Laboratorio 07: Configuración de red de videovigilancia IP Hikvision

## 1. Objetivos
- Implementar red de videovigilancia IP segmentada mediante VLAN CCTV (30) y VLAN Gestión (99)
- Configurar NVR Hikvision con disco 1 TB y 2 cámaras (una vía switch, otra directo a PoE del NVR)
- Gestionar NVR y canales desde estación Windows con iVMS-4200 y HiTools Delivery
- Configurar mallas de detección de movimiento y asociarlas a grabación por evento
- Validar direccionamiento, conectividad, Live View, reproducción, eventos y almacenamiento

## 2. Topología de Red

### VLANs y Direccionamiento
| Elemento | VLAN / Red | Dirección | Modo | Observaciones |
|----------|------------|-----------|------|---------------|
| Router - Gateway CCTV | VLAN 30 | 172.18.30.1/24 | Gateway | Enrutamiento hacia Gestión/Internet |
| Router - Gateway Gestión | VLAN 99 | 172.18.99.1/24 | Gateway | DHCP relay si servidor sirve a VLAN 30 |
| NVR Hikvision - LAN | VLAN 30 | 172.18.30.10/24 | Estática | Administración del NVR y canales |
| Cámara 1 - Switch | VLAN 30 | 172.18.30.20/24 | Estática/Reserva | Puerto access VLAN 30 |
| Servidor DHCP | VLAN 99 | 172.18.99.10/24 | Estática | Pools de Gestión y opcional CCTV |
| PC Administración | VLAN 99 | DHCP | Cliente | iVMS-4200 / HiTools Delivery |
| Cámara 2 - NVR PoE | Red PoE interna | Asignada por NVR | PoE directo | Se gestiona como canal del NVR |

### Equipo físico requerido
- NVR Hikvision con puertos PoE + HDD 1 TB
- 2 cámaras IP Hikvision compatibles
- Switch administrable con soporte VLAN (preferentemente PoE)
- Router con enrutamiento entre VLANs
- Servidor DHCP (Windows Server o Linux)
- PC Windows para administración
- Cableado UTP Cat 5e/6

## 3. Fases de Implementación

### Fase 1: Inventario y Preparación (Pre-requisitos)
- [ ] Registrar modelo y número de serie de NVR, cámaras, switch y router
- [ ] Verificar HDD 1 TB instalado correctamente en NVR (NVR apagado)
- [ ] Conectar monitor y mouse al NVR
- [ ] Conectar puerto LAN del NVR al switch
- [ ] Conectar Cámara 1 al switch PoE (puerto access VLAN 30) - usar inyector si switch no es PoE
- [ ] Conectar Cámara 2 directamente a puerto PoE del NVR
- [ ] Conectar servidor DHCP y PC Admin a puertos access VLAN 99
- [ ] Conectar uplink switch → router → Internet

### Fase 2: Configuración de Switch - VLANs
- [ ] Crear VLAN 30 (name: CCTV)
- [ ] Crear VLAN 99 (name: GESTION)
- [ ] Configurar puertos access:
  - Gi1/0/2 → CAMARA_1 (VLAN 30)
  - Gi1/0/3 → NVR_LAN (VLAN 30)
  - Gi1/0/24 → SERVIDOR_DHCP (VLAN 99)
  - Gi1/0/10 → PC_ADMIN (VLAN 99)
- [ ] Configurar puerto trunk uplink (Gi1/0/1) → allowed vlan 30,99 (puerto 1 con puerto 1 del 9300L)
- [ ] Habilitar spanning-tree portfast en puertos access

Ver `config/switch/config.txt` para comandos listos.

### Fase 3: Core C9300L - SVIs, WAN e Internet
- [ ] SVI Vlan30: ip 172.18.30.1/24 + ip helper-address 172.18.99.10
- [ ] SVI Vlan99: ip 172.18.99.1/24
- [ ] `ip routing` activo
- [ ] Gi1/0/1 trunk hacia C9200L (allowed 30,99)
- [ ] Gi1/0/24 WAN: `no switchport` + `ip address dhcp` (proveedor)
- [ ] Validar: desde PC Admin → ping gateway VLAN 99, ping NVR 172.18.30.10, acceso Internet

Ver `config/c9300L-core/config.txt`.

### Fase 4: Servidor DHCP (TU TAREA - máquina 192.168.45.128)
- [ ] Configurar IP estática: 172.18.99.10/24, gateway 172.18.99.1
- [ ] Crear ámbito GESTION: red 172.18.99.0/24, pool 172.18.99.100-180, gateway 172.18.99.1
- [ ] Crear ámbito CCTV (opcional): red 172.18.30.0/24, pool 172.18.30.100-180, gateway 172.18.30.1
- [ ] Configurar reservas DHCP para NVR (172.18.30.10) y Cámara 1 (172.18.30.20)
- [ ] Verificar entrega de IPs a PC Admin

Ver `config/dhcp/` para scripts Linux (isc-kea / dnsmasq) y guía Windows Server.

### Fase 5: Inicialización NVR Hikvision
- [ ] Encender NVR, completar asistente inicial
- [ ] Activar con usuario `admin` / contraseña laboratorio `XPTecsup2`
- [ ] Configurar fecha, zona horaria, NTP, formato hora
- [ ] Configurar interfaz LAN: IP 172.18.30.10/24, gateway 172.18.30.1, DNS según lab
- [ ] Storage / HDD: verificar disco 1 TB reconocido, inicializar (confirmar con docente), estado Normal
- [ ] Activar Overwrite

### Fase 6: Incorporar Cámara 1 (vía Switch)
- [ ] Conectar cámara a puerto access VLAN 30, confirmar PoE
- [ ] Usar HiTools Delivery para localizar cámara, activar si inactiva
- [ ] Configurar/reservar IP 172.18.30.20/24, gateway 172.18.30.1
- [ ] En NVR: Camera / IP Camera / Camera Management → Add por IP, protocolo Hikvision
- [ ] Verificar estado Online y Live View

### Fase 7: Incorporar Cámara 2 (directo a NVR PoE)
- [ ] Conectar cámara a puerto PoE libre del NVR
- [ ] Esperar negociación PoE y detección (Plug-and-Play asigna IP interna)
- [ ] En Camera Management verificar canal Online
- [ ] No cambiar red PoE interna salvo indicación docente
- [ ] Verificar Live View. Si requiere acceso web directo: habilitar Virtual Host

### Fase 8: Gestión desde iVMS-4200 (Windows)
- [ ] Instalar iVMS-4200 desde portal oficial Hikvision
- [ ] Device Management → Add NVR por IP 172.18.30.10
- [ ] Confirmar NVR Online con 2 canales
- [ ] Main View / Live View → arrastrar ambos canales
- [ ] Evidencia: captura con ambos canales simultáneos + estado Online

### Fase 9: Configuración Mallas Detección Movimiento
- [ ] NVR: Configuration / Camera / Event / Motion Detection
- [ ] Cámara 1: Enable → Draw Area (solo puertas, pasillos, accesos)
- [ ] Ajustar Sensitivity (medio inicial)
- [ ] Si soporta Human/Vehicle → habilitar solo objetivo requerido
- [ ] Arming Schedule → definir horarios
- [ ] Linkage Action → Trigger Recording
- [ ] Apply / Save → repetir para Cámara 2

### Fase 10: Asociación Detección ↔ Grabación
- [ ] Storage > Recording Schedule
- [ ] Cámara 1: Enable Schedule → tipo Motion/Event
- [ ] Programar: Lun-Sáb 00:00-24:00, Domingo sin programación
- [ ] Copiar a Cámara 2 → Apply
- [ ] Prueba positiva: moverse dentro malla 10-15 seg → Playback por evento → verificar clip
- [ ] Prueba negativa: cruzar fuera malla → verificar NO genera grabación

### Fase 11: Pruebas y Evidencias
| Prueba | Procedimiento | Resultado Esperado | Evidencia |
|--------|---------------|-------------------|-----------|
| DHCP Gestión | Renovar IP PC Admin | IP 172.18.99.x + GW 172.18.99.1 | ipconfig + captura |
| Inter-VLAN | Ping PC Admin → NVR | Respuesta NVR | Captura ping |
| Internet | Navegar desde PC Admin | Acceso disponible | Captura navegador |
| Cámara 1 | Live View NVR/iVMS | Canal Online | Captura |
| Cámara 2 | Live View NVR/iVMS | Canal Online | Captura |
| Motion 1 | Cruzar dentro malla | Evento + clip | Evento + Playback |
| Motion 2 | Moverse fuera malla | No evento | Registro |
| HDD | Storage / HDD | Normal, ~1 TB | Captura |
| Playback | Buscar clip por evento | Reproducción OK | Captura / video |

### Fase 12: Análisis de Almacenamiento
- [ ] Bitrate promedio por cámara
- [ ] GB/día ≈ bitrate_total (Mbps) × 10.8 × fracción_actividad
- [ ] Comparar vs 1 TB, determinar si 15 días alcanzables

### Fase 13: Preguntas de Análisis
Ver `index.md` sección preguntas. Pendiente responder.

### Fase 14: Documentación Final
- [ ] Observaciones, Conclusiones, Referencias
- [ ] Compilar capturas en `evidencias/`

## 4. Recursos Oficiales
- iVMS-4200: Hikvision Global → Software / iVMS-4200
- HiTools Delivery: Hikvision Global → HiTools Delivery (incluye SADP)
- NVR User Manual: Motion Detection, Recording Schedule

## 5. Notas
- Solo descargar desde portal oficial Hikvision
- Confirmar con docente antes de inicializar HDD
- Registrar modelos exactos antes de configurar

---
Estado: Plan creado. En curso Fase 4 DHCP (192.168.45.128).

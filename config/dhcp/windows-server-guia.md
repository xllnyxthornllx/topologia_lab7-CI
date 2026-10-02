# Guía DHCP Windows Server - Lab 07

## 1. IP estática del servidor
Panel / PowerShell (admin):
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.18.99.10 -PrefixLength 24 -DefaultGateway 172.18.99.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8,172.18.99.1
```

## 2. Instalar rol DHCP
```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName (hostname) -IPAddress 172.18.99.10
Restart-Service dhcpserver
```

## 3. Ámbito GESTION (obligatorio)
```powershell
Add-DhcpServerv4Scope -Name "GESTION" -StartRange 172.18.99.100 -EndRange 172.18.99.180 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 172.18.99.0 -Router 172.18.99.1 -DnsServer 8.8.8.8,172.18.99.1 -DnsDomain lab07.local
```

## 4. Ámbito CCTV (opcional, vía relay)
```powershell
Add-DhcpServerv4Scope -Name "CCTV" -StartRange 172.18.30.100 -EndRange 172.18.30.180 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 172.18.30.0 -Router 172.18.30.1 -DnsServer 8.8.8.8,172.18.30.1
```

## 5. Reservas (recomendado, reemplaza MAC)
```powershell
Add-DhcpServerv4Reservation -ScopeId 172.18.30.0 -IPAddress 172.18.30.10 -ClientId "AA-BB-CC-DD-EE-01" -Name "nvr-hikvision"
Add-DhcpServerv4Reservation -ScopeId 172.18.30.0 -IPAddress 172.18.30.20 -ClientId "AA-BB-CC-DD-EE-02" -Name "camara1"
```

## 6. Verificación
```powershell
Get-DhcpServerv4Scope
Get-DhcpServerv4Lease -ScopeId 172.18.99.0
Get-DhcpServerv4Lease -ScopeId 172.18.30.0
```
En PC Admin: `ipconfig /renew` → debe recibir 172.18.99.x, GW 172.18.99.1, DHCP 172.18.99.10.

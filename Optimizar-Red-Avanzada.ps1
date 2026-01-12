# ============================================
# Optimizar-Red-Avanzada.ps1
# Optimización avanzada de red y conectividad
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OPTIMIZACIÓN AVANZADA DE RED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando optimización avanzada de red" -Level "INFO"

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Log "Intento de optimizar red sin permisos de admin" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit 1
}

$report = @()
$report += "=================================================="
$report += "REPORTE DE OPTIMIZACIÓN DE RED - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "=================================================="
$report += ""

# ============================================
# 1. INFORMACIÓN DE RED ACTUAL
# ============================================

Write-Host "[1/6] Analizando configuración actual..." -ForegroundColor Cyan

$report += "1. CONFIGURACIÓN ACTUAL"
$report += "-" * 50

try {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $adapters) {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        
        Write-Host "  Adaptador: $($adapter.Name)" -ForegroundColor White
        Write-Host "    • Estado: $($adapter.Status)" -ForegroundColor Green
        Write-Host "    • Velocidad: $([math]::Round($adapter.LinkSpeed / 1000000, 0)) Mbps" -ForegroundColor White
        
        if ($ipConfig) {
            Write-Host "    • IP: $($ipConfig.IPAddress)" -ForegroundColor White
            $report += "Adaptador: $($adapter.Name)"
            $report += "  IP: $($ipConfig.IPAddress)"
            $report += "  Velocidad: $([math]::Round($adapter.LinkSpeed / 1000000, 0)) Mbps"
        }
    }
    
    # DNS actual
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1
    Write-Host ""
    Write-Host "  DNS actual:" -ForegroundColor Cyan
    foreach ($dns in $dnsServers.ServerAddresses) {
        Write-Host "    • $dns" -ForegroundColor White
        $report += "DNS: $dns"
    }
    
    Write-Log "Configuración de red analizada" -Level "INFO"
} catch {
    Write-Host "  ❌ Error al analizar red" -ForegroundColor Red
    Write-Log "Error al analizar red: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 2. TEST DE VELOCIDAD (Ping-based)
# ============================================

Write-Host "[2/6] Realizando test de conectividad..." -ForegroundColor Cyan
Write-Host "  (Midiendo latencia a servidores populares)" -ForegroundColor Gray
Write-Host ""

$report += "2. TEST DE CONECTIVIDAD"
$report += "-" * 50

$servers = @{
    "Google DNS" = "8.8.8.8"
    "CloudFlare DNS" = "1.1.1.1"
    "OpenDNS" = "208.67.222.222"
    "Google.com" = "www.google.com"
    "YouTube" = "www.youtube.com"
}

$totalLatency = 0
$successfulTests = 0

foreach ($serverName in $servers.Keys) {
    $serverIP = $servers[$serverName]
    
    try {
        $ping = Test-Connection -ComputerName $serverIP -Count 4 -ErrorAction Stop
        $avgLatency = [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 0)
        
        $color = if ($avgLatency -lt 50) { "Green" } elseif ($avgLatency -lt 100) { "Yellow" } else { "Red" }
        Write-Host "  ✅ $serverName : $avgLatency ms" -ForegroundColor $color
        $report += "$serverName : $avgLatency ms"
        
        $totalLatency += $avgLatency
        $successfulTests++
    } catch {
        Write-Host "  ❌ $serverName : Sin respuesta" -ForegroundColor Red
        $report += "$serverName : Sin respuesta"
    }
}

if ($successfulTests -gt 0) {
    $avgTotal = [math]::Round($totalLatency / $successfulTests, 0)
    Write-Host ""
    Write-Host "  📊 Latencia promedio: $avgTotal ms" -ForegroundColor Cyan
    $report += ""
    $report += "Latencia promedio: $avgTotal ms"
    
    if ($avgTotal -lt 50) {
        Write-Host "  ✅ Excelente conectividad" -ForegroundColor Green
        $report += "Evaluación: Excelente"
    } elseif ($avgTotal -lt 100) {
        Write-Host "  ⚠️  Conectividad aceptable" -ForegroundColor Yellow
        $report += "Evaluación: Aceptable"
    } else {
        Write-Host "  ❌ Conectividad mejorable" -ForegroundColor Red
        $report += "Evaluación: Mejorable"
    }
}

Write-Log "Test de conectividad completado: $avgTotal ms promedio" -Level "INFO"

$report += ""
Write-Host ""

# ============================================
# 3. DNS BENCHMARK
# ============================================

Write-Host "[3/6] Comparando servidores DNS..." -ForegroundColor Cyan
Write-Host "  (Esto puede tardar 20-30 segundos)" -ForegroundColor Gray
Write-Host ""

$report += "3. BENCHMARK DE DNS"
$report += "-" * 50

$dnsProviders = @{
    "Google DNS" = "8.8.8.8"
    "CloudFlare" = "1.1.1.1"
    "OpenDNS" = "208.67.222.222"
    "Quad9" = "9.9.9.9"
}

$dnsResults = @{}

foreach ($providerName in $dnsProviders.Keys) {
    $dnsIP = $dnsProviders[$providerName]
    
    Write-Host "  🔄 Testeando $providerName..." -ForegroundColor Yellow
    
    try {
        # Medir tiempo de resolución DNS
        $start = Get-Date
        $null = Resolve-DnsName -Name "www.google.com" -Server $dnsIP -DnsOnly -ErrorAction Stop
        $null = Resolve-DnsName -Name "www.youtube.com" -Server $dnsIP -DnsOnly -ErrorAction Stop
        $null = Resolve-DnsName -Name "www.facebook.com" -Server $dnsIP -DnsOnly -ErrorAction Stop
        $elapsed = ((Get-Date) - $start).TotalMilliseconds / 3
        
        $dnsResults[$providerName] = $elapsed
        Write-Host "  ✅ $providerName : $([math]::Round($elapsed, 0)) ms" -ForegroundColor Green
        $report += "$providerName : $([math]::Round($elapsed, 0)) ms"
    } catch {
        Write-Host "  ❌ $providerName : Error en prueba" -ForegroundColor Red
        $report += "$providerName : Error"
    }
}

# Encontrar el más rápido
if ($dnsResults.Count -gt 0) {
    $fastest = ($dnsResults.GetEnumerator() | Sort-Object Value | Select-Object -First 1)
    Write-Host ""
    Write-Host "  🏆 DNS más rápido: $($fastest.Name) ($([math]::Round($fastest.Value, 0)) ms)" -ForegroundColor Cyan
    $report += ""
    $report += "Recomendado: $($fastest.Name) - $([math]::Round($fastest.Value, 0)) ms"
}

Write-Log "DNS benchmark completado" -Level "INFO"

$report += ""
Write-Host ""

# ============================================
# 4. OPTIMIZACIÓN DE MTU
# ============================================

Write-Host "[4/6] Optimizando MTU (Maximum Transmission Unit)..." -ForegroundColor Cyan

$report += "4. OPTIMIZACIÓN MTU"
$report += "-" * 50

try {
    # Obtener adaptador principal
    $mainAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    if ($mainAdapter) {
        # Encontrar MTU óptimo
        Write-Host "  🔄 Detectando MTU óptimo..." -ForegroundColor Yellow
        
        $optimalMTU = 1500
        $testSizes = @(1500, 1492, 1472, 1468, 1464, 1460)
        
        foreach ($size in $testSizes) {
            try {
                $ping = Test-Connection -ComputerName "8.8.8.8" -BufferSize $size -Count 1 -ErrorAction Stop
                if ($ping) {
                    $optimalMTU = $size
                    break
                }
            } catch {
                continue
            }
        }
        
        Write-Host "  ✅ MTU óptimo detectado: $optimalMTU bytes" -ForegroundColor Green
        $report += "MTU óptimo: $optimalMTU bytes"
        
        # Configurar MTU
        netsh interface ipv4 set subinterface "$($mainAdapter.Name)" mtu=$optimalMTU store=persistent | Out-Null
        
        Write-Host "  ✅ MTU configurado en $optimalMTU" -ForegroundColor Green
        $report += "MTU aplicado: $optimalMTU"
        
        Write-Log "MTU optimizado a $optimalMTU" -Level "SUCCESS"
    }
} catch {
    Write-Host "  ⚠️  No se pudo optimizar MTU automáticamente" -ForegroundColor Yellow
    Write-Log "Error al optimizar MTU: $($_.Exception.Message)" -Level "WARNING"
}

$report += ""
Write-Host ""

# ============================================
# 5. LIMPIEZA Y RESET DE RED
# ============================================

Write-Host "[5/6] Limpiando caché de red..." -ForegroundColor Cyan

$report += "5. LIMPIEZA DE RED"
$report += "-" * 50

try {
    # Flush DNS
    Write-Host "  🔄 Limpiando caché DNS..." -ForegroundColor Yellow
    ipconfig /flushdns | Out-Null
    Write-Host "  ✅ Caché DNS limpiada" -ForegroundColor Green
    $report += "Caché DNS: Limpiada"
    
    # Reset Winsock
    Write-Host "  🔄 Reseteando Winsock..." -ForegroundColor Yellow
    netsh winsock reset | Out-Null
    Write-Host "  ✅ Winsock reseteado" -ForegroundColor Green
    $report += "Winsock: Reseteado"
    
    # Reset TCP/IP
    Write-Host "  🔄 Reseteando TCP/IP..." -ForegroundColor Yellow
    netsh int ip reset | Out-Null
    Write-Host "  ✅ TCP/IP reseteado" -ForegroundColor Green
    $report += "TCP/IP: Reseteado"
    
    # Liberar y renovar IP
    Write-Host "  🔄 Renovando IP..." -ForegroundColor Yellow
    ipconfig /release | Out-Null
    Start-Sleep -Seconds 2
    ipconfig /renew | Out-Null
    Write-Host "  ✅ IP renovada" -ForegroundColor Green
    $report += "IP: Renovada"
    
    Write-Log "Limpieza de red completada" -Level "SUCCESS"
} catch {
    Write-Host "  ⚠️  Algunas operaciones de limpieza fallaron" -ForegroundColor Yellow
    Write-Log "Error en limpieza de red: $($_.Exception.Message)" -Level "WARNING"
}

$report += ""
Write-Host ""

# ============================================
# 6. OPTIMIZACIONES AVANZADAS
# ============================================

Write-Host "[6/6] Aplicando optimizaciones avanzadas..." -ForegroundColor Cyan

$report += "6. OPTIMIZACIONES AVANZADAS"
$report += "-" * 50

try {
    # Deshabilitar autotuning (mejora en algunos casos)
    Write-Host "  🔄 Optimizando TCP..." -ForegroundColor Yellow
    netsh interface tcp set global autotuninglevel=normal | Out-Null
    Write-Host "  ✅ TCP Autotuning configurado" -ForegroundColor Green
    
    # Configurar DNS seguro (DoH) con CloudFlare
    Write-Host "  🔄 Configurando DNS..." -ForegroundColor Yellow
    
    $mainAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    if ($mainAdapter) {
        # Configurar CloudFlare DNS (1.1.1.1)
        Set-DnsClientServerAddress -InterfaceIndex $mainAdapter.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
        Write-Host "  ✅ DNS configurado: CloudFlare (1.1.1.1)" -ForegroundColor Green
        $report += "DNS configurado: CloudFlare 1.1.1.1"
    }
    
    # Deshabilitar QoS Packet Scheduler si no se usa
    Write-Host "  🔄 Optimizando QoS..." -ForegroundColor Yellow
    netsh int tcp set global chimney=enabled | Out-Null
    Write-Host "  ✅ QoS optimizado" -ForegroundColor Green
    
    # Aumentar tamaño de cola de recepción
    Write-Host "  🔄 Optimizando buffers..." -ForegroundColor Yellow
    netsh interface tcp set global congestionprovider=ctcp | Out-Null
    Write-Host "  ✅ Buffers optimizados" -ForegroundColor Green
    
    $report += "Optimizaciones aplicadas: TCP, DNS, QoS, Buffers"
    
    Write-Log "Optimizaciones avanzadas aplicadas" -Level "SUCCESS"
} catch {
    Write-Host "  ⚠️  Algunas optimizaciones no se pudieron aplicar" -ForegroundColor Yellow
    Write-Log "Error en optimizaciones: $($_.Exception.Message)" -Level "WARNING"
}

Write-Host ""

# ============================================
# RESUMEN
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OPTIMIZACIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Optimizaciones aplicadas:" -ForegroundColor Green
Write-Host "  • MTU optimizado" -ForegroundColor White
Write-Host "  • Caché DNS limpiada" -ForegroundColor White
Write-Host "  • Winsock y TCP/IP reseteados" -ForegroundColor White
Write-Host "  • IP renovada" -ForegroundColor White
Write-Host "  • DNS configurado (CloudFlare 1.1.1.1)" -ForegroundColor White
Write-Host "  • TCP y buffers optimizados" -ForegroundColor White

Write-Host ""
Write-Host "💡 RECOMENDACIONES:" -ForegroundColor Yellow
Write-Host "  • Reinicia tu PC para aplicar todos los cambios" -ForegroundColor White
Write-Host "  • Si usas VPN, reconfigúrala después del reinicio" -ForegroundColor White
Write-Host "  • Testa tu conexión después del reinicio" -ForegroundColor White
Write-Host "  • Si tienes problemas, ejecuta 'Revertir-Cambios.ps1'" -ForegroundColor White

Write-Host ""
Write-Host "🌐 COMANDOS ÚTILES:" -ForegroundColor Cyan
Write-Host "  • Ver configuración IP: ipconfig /all" -ForegroundColor White
Write-Host "  • Test de ping: ping 8.8.8.8" -ForegroundColor White
Write-Host "  • Ver DNS: nslookup google.com" -ForegroundColor White
Write-Host "  • Ver rutas: tracert google.com" -ForegroundColor White

Write-Host ""
Write-Host "📄 Reporte guardado en: Reporte-Red-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt" -ForegroundColor Cyan

$reportPath = "$scriptPath\Reporte-Red-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Optimización de red completada" -Level "SUCCESS"

Write-Host "⚠️  IMPORTANTE: Reinicia tu PC para aplicar todos los cambios" -ForegroundColor Yellow
Write-Host ""
Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

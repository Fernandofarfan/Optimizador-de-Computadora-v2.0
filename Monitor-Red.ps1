<#
.SYNOPSIS
    Monitor de Red en Tiempo Real para Windows
.DESCRIPTION
    Monitorea tráfico de red por aplicación, detecta conexiones inusuales,
    bloquea aplicaciones con consumo excesivo y realiza test de velocidad.
.NOTES
    Versión: 3.0.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11, Permisos de Administrador
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:NetworkLogPath = "$env:USERPROFILE\OptimizadorPC-NetworkLog.json"
$Global:NetworkScriptVersion = "4.0.0"
$Global:MonitoringActive = $false

# Importar Logger si existe
if (Test-Path ".\Logger.ps1") {
    . ".\Logger.ps1"
    $Global:UseLogger = $true
} else {
    $Global:UseLogger = $false
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "  ║                                                              ║" -ForegroundColor Blue
    Write-Host "  ║          📡 MONITOR DE RED EN TIEMPO REAL                   ║" -ForegroundColor White
    Write-Host "  ║                      Versión $Global:NetworkScriptVersion                      ║" -ForegroundColor Blue
    Write-Host "  ║                                                              ║" -ForegroundColor Blue
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Get-NetworkTrafficByProcess {
    <#
    .SYNOPSIS
        Obtiene tráfico de red por proceso
    #>
    Write-Host "`n[*] Analizando tráfico de red por proceso..." -ForegroundColor Cyan
    Write-Log "Iniciando análisis de tráfico por proceso" "INFO"
    
    $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
    $trafficData = @{}
    
    foreach ($conn in $connections) {
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            
            if ($process) {
                $processName = $process.ProcessName
                
                if (-not $trafficData.ContainsKey($processName)) {
                    $trafficData[$processName] = @{
                        Connections = 0
                        SendBytes = 0
                        RecvBytes = 0
                        ProcessId = $conn.OwningProcess
                        LocalPorts = @()
                        RemotePorts = @()
                    }
                }
                
                $trafficData[$processName].Connections++
                $trafficData[$processName].LocalPorts += $conn.LocalPort
                $trafficData[$processName].RemotePorts += $conn.RemotePort
            }
        }
        catch {
            Write-Log "Error procesando conexión: $_" "WARNING"
        }
    }
    
    # Verificar estadísticas de adaptadores de red disponibles
    Get-NetAdapterStatistics -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              TRÁFICO DE RED POR APLICACIÓN                           ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $sortedProcesses = $trafficData.GetEnumerator() | Sort-Object { $_.Value.Connections } -Descending | Select-Object -First 15
    
    foreach ($proc in $sortedProcesses) {
        $name = $proc.Key
        $data = $proc.Value
        $connCount = $data.Connections
        
        Write-Host "  📊 $name" -ForegroundColor Yellow
        Write-Host "     Conexiones activas: $connCount" -ForegroundColor Gray
        Write-Host "     PID: $($data.ProcessId)" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    return $trafficData
}

function Start-RealTimeMonitoring {
    <#
    .SYNOPSIS
        Inicia monitoreo en tiempo real con actualización cada 2 segundos
    #>
    Write-Host "`n[*] Iniciando monitor en tiempo real..." -ForegroundColor Cyan
    Write-Host "[i] Presione CTRL+C para detener" -ForegroundColor Yellow
    Write-Host ""
    Write-Log "Monitor de red en tiempo real iniciado" "INFO"
    
    $Global:MonitoringActive = $true
    $iteration = 0
    
    try {
        while ($Global:MonitoringActive) {
            $iteration++
            
            # Obtener estadísticas de adaptador
            $adapter = Get-NetAdapterStatistics | Select-Object -First 1
            
            if ($adapter) {
                $sentMB = [math]::Round($adapter.SentBytes / 1MB, 2)
                $recvMB = [math]::Round($adapter.ReceivedBytes / 1MB, 2)
                
                # Posicionar cursor para redibuj ar
                if ($iteration -gt 1) {
                    [Console]::SetCursorPosition(0, [Console]::CursorTop - 15)
                }
                
                Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
                Write-Host "║          MONITOR DE RED - Iteración #$iteration".PadRight(65) + "║" -ForegroundColor White
                Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
                Write-Host "║  Adaptador: $($adapter.Name.PadRight(45))║" -ForegroundColor Cyan
                Write-Host "║  Enviados: $($sentMB.ToString().PadRight(10)) MB                           ║" -ForegroundColor Green
                Write-Host "║  Recibidos: $($recvMB.ToString().PadRight(10)) MB                          ║" -ForegroundColor Green
                Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
                
                # Top 5 procesos con conexiones
                $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
                $processConnections = @{}
                
                foreach ($conn in $connections) {
                    try {
                        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                        if ($proc) {
                            $name = $proc.ProcessName
                            if (-not $processConnections.ContainsKey($name)) {
                                $processConnections[$name] = 0
                            }
                            $processConnections[$name]++
                        }
                    }
                    catch { }
                }
                
                $topProcesses = $processConnections.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5
                
                Write-Host "║  Top 5 Aplicaciones:                                           ║" -ForegroundColor Yellow
                
                foreach ($proc in $topProcesses) {
                    $line = "║  • $($proc.Key): $($proc.Value) conexiones"
                    $line = $line.PadRight(65) + "║"
                    Write-Host $line -ForegroundColor Gray
                }
                
                Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
                Write-Host ""
            }
            
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-Host "`n[!] Monitor detenido: $_" -ForegroundColor Yellow
        Write-Log "Monitor detenido: $_" "INFO"
    }
    finally {
        $Global:MonitoringActive = $false
    }
}

function Get-UnusualConnections {
    <#
    .SYNOPSIS
        Detecta conexiones inusuales o a puertos no comunes
    #>
    Write-Host "`n[*] Detectando conexiones inusuales..." -ForegroundColor Cyan
    Write-Log "Analizando conexiones inusuales" "INFO"
    
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    $unusualConnections = @()
    
    # Puertos comunes conocidos
    $commonPorts = @(80, 443, 22, 21, 25, 110, 143, 53, 3389, 445, 139, 135)
    
    # Servicios conocidos seguros
    $trustedProcesses = @("chrome", "firefox", "msedge", "Teams", "OneDrive", "Dropbox", "svchost", "System")
    
    foreach ($conn in $connections) {
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            
            if ($process) {
                $processName = $process.ProcessName
                $remotePort = $conn.RemotePort
                $remoteAddress = $conn.RemoteAddress
                
                # Verificar si es conexión inusual
                $isUnusual = $false
                $reason = ""
                
                # Conexión a puerto no común
                if ($remotePort -notin $commonPorts -and $remotePort -gt 0) {
                    $isUnusual = $true
                    $reason = "Puerto no común ($remotePort)"
                }
                
                # Proceso no confiable
                if ($processName -notin $trustedProcesses -and $remoteAddress -notmatch '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)') {
                    $isUnusual = $true
                    $reason += " | Proceso: $processName"
                }
                
                if ($isUnusual) {
                    $unusualConnections += [PSCustomObject]@{
                        ProcessName = $processName
                        ProcessId = $conn.OwningProcess
                        LocalAddress = $conn.LocalAddress
                        LocalPort = $conn.LocalPort
                        RemoteAddress = $remoteAddress
                        RemotePort = $remotePort
                        State = $conn.State
                        Reason = $reason
                    }
                }
            }
        }
        catch {
            Write-Log "Error analizando conexión: $_" "WARNING"
        }
    }
    
    if ($unusualConnections.Count -gt 0) {
        Write-Host "`n  [!] Se detectaron $($unusualConnections.Count) conexiones inusuales:" -ForegroundColor Red
        Write-Host ""
        
        foreach ($conn in ($unusualConnections | Select-Object -First 10)) {
            Write-Host "  ⚠️  $($conn.ProcessName) (PID: $($conn.ProcessId))" -ForegroundColor Yellow
            Write-Host "     $($conn.RemoteAddress):$($conn.RemotePort) [$($conn.State)]" -ForegroundColor Gray
            Write-Host "     Razón: $($conn.Reason)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        Write-Log "Detectadas $($unusualConnections.Count) conexiones inusuales" "WARNING"
    }
    else {
        Write-Host "  [✓] No se detectaron conexiones inusuales" -ForegroundColor Green
        Write-Log "No se detectaron conexiones inusuales" "SUCCESS"
    }
    
    return $unusualConnections
}

function Block-ProcessNetwork {
    <#
    .SYNOPSIS
        Bloquea conexiones de red de un proceso específico
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    
    Write-Host "`n[*] Bloqueando conexiones de: $ProcessName..." -ForegroundColor Cyan
    Write-Log "Intentando bloquear conexiones de: $ProcessName" "INFO"
    
    try {
        # Obtener ruta del ejecutable
        $process = Get-Process -Name $ProcessName -ErrorAction Stop | Select-Object -First 1
        $exePath = $process.Path
        
        if (-not $exePath) {
            Write-Host "  [✗] No se pudo obtener la ruta del ejecutable" -ForegroundColor Red
            return $false
        }
        
        # Crear regla de firewall para bloquear salida
        $ruleName = "Optimizador-Block-$ProcessName"
        
        # Eliminar regla existente si existe
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        
        # Crear nueva regla de bloqueo
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Outbound `
            -Program $exePath `
            -Action Block `
            -Enabled True `
            -ErrorAction Stop | Out-Null
        
        Write-Host "  [✓] Conexiones de $ProcessName bloqueadas correctamente" -ForegroundColor Green
        Write-Host "  [i] Para desbloquear, use la opción de gestión de reglas" -ForegroundColor Cyan
        Write-Log "Conexiones de $ProcessName bloqueadas con firewall" "SUCCESS"
        
        return $true
    }
    catch {
        Write-Host "  [✗] Error al bloquear: $_" -ForegroundColor Red
        Write-Log "Error al bloquear conexiones de $($ProcessName): $_" "ERROR"
        return $false
    }
}

function Unblock-ProcessNetwork {
    <#
    .SYNOPSIS
        Desbloquea conexiones de red de un proceso
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    
    Write-Host "`n[*] Desbloqueando conexiones de: $ProcessName..." -ForegroundColor Cyan
    
    try {
        $ruleName = "Optimizador-Block-$ProcessName"
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        
        Write-Host "  [✓] Conexiones de $ProcessName desbloqueadas" -ForegroundColor Green
        Write-Log "Conexiones de $ProcessName desbloqueadas" "SUCCESS"
        return $true
    }
    catch {
        Write-Host "  [✗] Error al desbloquear: $_" -ForegroundColor Red
        Write-Log "Error al desbloquear conexiones: $_" "ERROR"
        return $false
    }
}

function Show-BlockedProcesses {
    <#
    .SYNOPSIS
        Muestra procesos bloqueados por el optimizador
    #>
    Write-Host "`n[*] Procesos bloqueados por Optimizador:" -ForegroundColor Cyan
    
    $rules = Get-NetFirewallRule -DisplayName "Optimizador-Block-*" -ErrorAction SilentlyContinue
    
    if ($rules) {
        Write-Host ""
        foreach ($rule in $rules) {
            $processName = $rule.DisplayName -replace "Optimizador-Block-", ""
            $enabled = if ($rule.Enabled) { "✓ Activo" } else { "✗ Inactivo" }
            
            Write-Host "  • $processName - $enabled" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "  Total: $($rules.Count) proceso(s) bloqueado(s)" -ForegroundColor Gray
    }
    else {
        Write-Host "  [i] No hay procesos bloqueados actualmente" -ForegroundColor Yellow
    }
}

function Test-InternetSpeed {
    <#
    .SYNOPSIS
        Realiza test de velocidad de internet (ping, download estimado)
    #>
    Write-Host "`n[*] Realizando test de velocidad de internet..." -ForegroundColor Cyan
    Write-Log "Iniciando test de velocidad" "INFO"
    
    # Test de latencia (ping)
    Write-Host "  [1/2] Midiendo latencia..." -ForegroundColor Yellow
    
    $pingTargets = @("8.8.8.8", "1.1.1.1", "208.67.222.222")
    $latencies = @()
    
    foreach ($target in $pingTargets) {
        try {
            $ping = Test-Connection -ComputerName $target -Count 4 -ErrorAction Stop
            $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
            $latencies += $avgLatency
        }
        catch {
            Write-Log "Error en ping a $target`: $_" "WARNING"
        }
    }
    
    if ($latencies.Count -gt 0) {
        $avgLatency = [math]::Round(($latencies | Measure-Object -Average).Average, 2)
        
        $latencyStatus = if ($avgLatency -lt 50) {
            "Excelente"
        } elseif ($avgLatency -lt 100) {
            "Buena"
        } elseif ($avgLatency -lt 200) {
            "Aceptable"
        } else {
            "Lenta"
        }
        
        Write-Host "  [✓] Latencia promedio: $avgLatency ms ($latencyStatus)" -ForegroundColor Green
    }
    
    # Test de descarga (estimación con archivo pequeño)
    Write-Host "  [2/2] Estimando velocidad de descarga..." -ForegroundColor Yellow
    
    $testUrl = "http://speedtest.tele2.net/1MB.zip"
    $testFile = "$env:TEMP\speedtest.tmp"
    
    try {
        $startTime = Get-Date
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($testUrl, $testFile)
        $endTime = Get-Date
        
        $duration = ($endTime - $startTime).TotalSeconds
        $fileSizeMB = 1 # 1 MB
        $speedMbps = [math]::Round(($fileSizeMB * 8) / $duration, 2)
        
        Write-Host "  [✓] Velocidad estimada: $speedMbps Mbps" -ForegroundColor Green
        
        # Limpiar archivo temporal
        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        
        Write-Log "Test de velocidad completado: $avgLatency ms, $speedMbps Mbps" "SUCCESS"
    }
    catch {
        Write-Host "  [✗] No se pudo medir velocidad de descarga: $_" -ForegroundColor Red
        Write-Log "Error en test de velocidad: $_" "ERROR"
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          RESUMEN DE TEST DE VELOCIDAD             ║" -ForegroundColor White
    Write-Host "╠════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    if ($latencies.Count -gt 0) {
        Write-Host "║  Latencia: $avgLatency ms - $latencyStatus".PadRight(53) + "║" -ForegroundColor Green
    }
    if ($speedMbps) {
        Write-Host "║  Descarga: $speedMbps Mbps".PadRight(53) + "║" -ForegroundColor Green
    }
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Get-WHOISInfo {
    <#
    .SYNOPSIS
        Obtiene información WHOIS básica de una IP
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )
    
    Write-Host "`n[*] Consultando información de: $IPAddress..." -ForegroundColor Cyan
    
    try {
        # Intentar obtener hostname
        $hostname = [System.Net.Dns]::GetHostEntry($IPAddress).HostName
        Write-Host "  [✓] Hostname: $hostname" -ForegroundColor Green
    }
    catch {
        Write-Host "  [i] No se pudo resolver hostname" -ForegroundColor Yellow
    }
    
    # Información geográfica básica (requeriría API externa para más detalles)
    Write-Host "  [i] Para información WHOIS completa, use: https://whois.domaintools.com/$IPAddress" -ForegroundColor Cyan
    
    Write-Log "Información WHOIS consultada para: $IPAddress" "INFO"
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 📊 Tráfico por Aplicación                 ║" -ForegroundColor Cyan
        Write-Host "  ║  [2] 🔴 Monitor en Tiempo Real                 ║" -ForegroundColor Red
        Write-Host "  ║  [3] ⚠️  Detectar Conexiones Inusuales         ║" -ForegroundColor Yellow
        Write-Host "  ║  [4] 🚫 Bloquear Aplicación                    ║" -ForegroundColor Magenta
        Write-Host "  ║  [5] ✅ Desbloquear Aplicación                 ║" -ForegroundColor Green
        Write-Host "  ║  [6] 📋 Ver Aplicaciones Bloqueadas            ║" -ForegroundColor Blue
        Write-Host "  ║  [7] 🚀 Test de Velocidad Internet             ║" -ForegroundColor Cyan
        Write-Host "  ║  [8] 🔍 Consultar WHOIS de IP                  ║" -ForegroundColor White
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                Get-NetworkTrafficByProcess | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '2' {
                Start-RealTimeMonitoring
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                Get-UnusualConnections | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                $processName = Read-Host "`n  Ingrese el nombre del proceso a bloquear (ej: chrome)"
                
                if ($processName) {
                    Block-ProcessNetwork -ProcessName $processName
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                Show-BlockedProcesses
                $processName = Read-Host "`n  Ingrese el nombre del proceso a desbloquear"
                
                if ($processName) {
                    Unblock-ProcessNetwork -ProcessName $processName
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                Show-BlockedProcesses
                Read-Host "`nPresione ENTER para continuar"
            }
            '7' {
                Test-InternetSpeed
                Read-Host "`nPresione ENTER para continuar"
            }
            '8' {
                $ipAddress = Read-Host "`n  Ingrese la dirección IP"
                
                if ($ipAddress) {
                    Get-WHOISInfo -IPAddress $ipAddress
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                Write-Host "`n  [✓] Saliendo del Monitor de Red..." -ForegroundColor Green
                Write-Log "Monitor de Red cerrado" "INFO"
                return
            }
            default {
                Write-Host "`n  [✗] Opción inválida" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "`n[✗] ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Host "[i] Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'" -ForegroundColor Yellow
    Read-Host "`nPresione ENTER para salir"
    exit 1
}

# Iniciar menú
Show-Menu

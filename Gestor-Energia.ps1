<#
.SYNOPSIS
    Gestor Inteligente de Energía y Batería para Windows
.DESCRIPTION
    Gestión completa de perfiles de energía, análisis de consumo,
    procesos que impiden suspensión y salud de batería en portátiles.
.NOTES
    Versión: 2.9.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11, Permisos de Administrador
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:EnergyProfilesPath = "$env:USERPROFILE\OptimizadorPC-EnergyProfiles.json"
$Global:EnergyScriptVersion = "2.9.0"

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
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║                                                              ║" -ForegroundColor Yellow
    Write-Host "  ║          🔋 GESTOR INTELIGENTE DE ENERGÍA                   ║" -ForegroundColor White
    Write-Host "  ║                      Versión $Global:EnergyScriptVersion                      ║" -ForegroundColor Yellow
    Write-Host "  ║                                                              ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
}

function Get-PowerPlan {
    <#
    .SYNOPSIS
        Obtiene el plan de energía actual
    #>
    Write-Host "`n[*] Obteniendo plan de energía actual..." -ForegroundColor Cyan
    
    try {
        $activePlan = powercfg /getactivescheme
        
        if ($activePlan -match '\(([^)]+)\)') {
            $planName = $matches[1]
            Write-Host "  [✓] Plan activo: $planName" -ForegroundColor Green
            Write-Log "Plan de energía activo: $planName" "INFO"
            return $planName
        }
    }
    catch {
        Write-Host "  [✗] Error al obtener plan: $_" -ForegroundColor Red
        Write-Log "Error al obtener plan de energía: $_" "ERROR"
    }
    
    return "Desconocido"
}

function Get-AvailablePowerPlans {
    <#
    .SYNOPSIS
        Lista todos los planes de energía disponibles
    #>
    Write-Host "`n[*] Planes de energía disponibles:" -ForegroundColor Cyan
    
    $plans = powercfg /list
    $planList = @()
    
    foreach ($line in $plans) {
        if ($line -match 'GUID: ([a-f0-9-]+)\s+\(([^)]+)\)') {
            $guid = $matches[1]
            $name = $matches[2]
            $isActive = $line -match '\*'
            
            $planInfo = [PSCustomObject]@{
                GUID = $guid
                Name = $name
                IsActive = $isActive
            }
            
            $planList += $planInfo
            
            $status = if ($isActive) { " [ACTIVO]" } else { "" }
            $color = if ($isActive) { "Green" } else { "White" }
            
            Write-Host "  • $name$status" -ForegroundColor $color
            Write-Host "    GUID: $guid" -ForegroundColor Gray
        }
    }
    
    return $planList
}

function Set-PowerPlan {
    <#
    .SYNOPSIS
        Cambia el plan de energía activo
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$PlanGUID
    )
    
    Write-Host "`n[*] Cambiando plan de energía..." -ForegroundColor Cyan
    
    try {
        powercfg /setactive $PlanGUID
        Write-Host "  [✓] Plan de energía cambiado correctamente" -ForegroundColor Green
        Write-Log "Plan de energía cambiado a GUID: $PlanGUID" "SUCCESS"
        return $true
    }
    catch {
        Write-Host "  [✗] Error al cambiar plan: $_" -ForegroundColor Red
        Write-Log "Error al cambiar plan de energía: $_" "ERROR"
        return $false
    }
}

function New-CustomPowerPlan {
    <#
    .SYNOPSIS
        Crea un plan de energía personalizado
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$PlanName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("MaxPerformance", "Balanced", "PowerSaver", "Gaming")]
        [string]$ProfileType
    )
    
    Write-Host "`n[*] Creando plan personalizado: $PlanName..." -ForegroundColor Cyan
    
    # GUIDs de planes base
    $baseGuids = @{
        MaxPerformance = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  # Alto rendimiento
        Balanced = "381b4222-f694-41f0-9685-ff5bb260df2e"        # Equilibrado
        PowerSaver = "a1841308-3541-4fab-bc81-f71556f20b4a"      # Economizador
        Gaming = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"          # Alto rendimiento
    }
    
    $baseGuid = $baseGuids[$ProfileType]
    
    try {
        # Duplicar plan base
        $result = powercfg /duplicatescheme $baseGuid
        
        if ($result -match 'GUID: ([a-f0-9-]+)') {
            $newGuid = $matches[1]
            
            # Renombrar plan
            powercfg /changename $newGuid "$PlanName" "Plan personalizado por Optimizador PC"
            
            Write-Host "  [✓] Plan '$PlanName' creado correctamente" -ForegroundColor Green
            Write-Log "Plan de energía personalizado creado: $PlanName (GUID: $newGuid)" "SUCCESS"
            
            # Aplicar configuraciones según tipo
            switch ($ProfileType) {
                "MaxPerformance" {
                    # Desactivar suspensión en CA
                    powercfg /change standby-timeout-ac 0
                    # Desactivar hibernación
                    powercfg /change hibernate-timeout-ac 0
                    # Pantalla nunca se apaga
                    powercfg /change monitor-timeout-ac 0
                    # CPU al 100%
                    powercfg /setacvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMAX 100
                }
                "Balanced" {
                    # Suspensión a los 30 min
                    powercfg /change standby-timeout-ac 30
                    # Pantalla a los 15 min
                    powercfg /change monitor-timeout-ac 15
                }
                "PowerSaver" {
                    # Suspensión a los 10 min
                    powercfg /change standby-timeout-ac 10
                    # Pantalla a los 5 min
                    powercfg /change monitor-timeout-ac 5
                    # CPU al 50%
                    powercfg /setacvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMAX 50
                }
                "Gaming" {
                    # Configuración gaming optimizada
                    powercfg /change standby-timeout-ac 0
                    powercfg /change hibernate-timeout-ac 0
                    powercfg /change monitor-timeout-ac 0
                    # USB no suspende
                    powercfg /setacvalueindex $newGuid SUB_USB USBSELECTIVESUSPEND 0
                }
            }
            
            return $newGuid
        }
    }
    catch {
        Write-Host "  [✗] Error al crear plan: $_" -ForegroundColor Red
        Write-Log "Error al crear plan personalizado: $_" "ERROR"
        return $null
    }
}

function Get-BatteryStatus {
    <#
    .SYNOPSIS
        Obtiene información detallada de la batería (solo portátiles)
    #>
    Write-Host "`n[*] Analizando batería del sistema..." -ForegroundColor Cyan
    
    try {
        $battery = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue
        
        if (-not $battery) {
            Write-Host "  [i] No se detectó batería (sistema de escritorio)" -ForegroundColor Yellow
            return $null
        }
        
        # Información básica
        $batteryInfo = [PSCustomObject]@{
            Name = $battery.Name
            Status = $battery.Status
            EstimatedChargeRemaining = $battery.EstimatedChargeRemaining
            EstimatedRunTime = $battery.EstimatedRunTime
            BatteryStatus = switch ($battery.BatteryStatus) {
                1 { "Descargando" }
                2 { "Conectado a CA" }
                3 { "Totalmente cargada" }
                4 { "Baja" }
                5 { "Crítica" }
                6 { "Cargando" }
                default { "Desconocido" }
            }
            Chemistry = switch ($battery.Chemistry) {
                1 { "Otra" }
                2 { "Desconocida" }
                3 { "Plomo-Ácido" }
                4 { "Níquel-Cadmio" }
                5 { "Níquel-Metal Hidruro" }
                6 { "Litio-Ion" }
                7 { "Litio-Polímero" }
                8 { "Zinc-Aire" }
                default { "Desconocida" }
            }
        }
        
        # Calcular salud de batería
        $batteryReport = powercfg /batteryreport /output "$env:TEMP\battery-report.html" 2>&1
        
        Write-Host "`n  ╔════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "  ║          INFORMACIÓN DE BATERÍA                ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor Yellow
        Write-Host "  ║  Nombre: $($batteryInfo.Name.PadRight(35)) ║" -ForegroundColor Cyan
        Write-Host "  ║  Estado: $($batteryInfo.BatteryStatus.PadRight(35)) ║" -ForegroundColor Cyan
        Write-Host "  ║  Carga: $($batteryInfo.EstimatedChargeRemaining)%".PadRight(41) + "║" -ForegroundColor $(if ($batteryInfo.EstimatedChargeRemaining -lt 20) { "Red" } elseif ($batteryInfo.EstimatedChargeRemaining -lt 50) { "Yellow" } else { "Green" })
        
        if ($batteryInfo.EstimatedRunTime -ne 71582788) {
            $hours = [math]::Floor($batteryInfo.EstimatedRunTime / 60)
            $minutes = $batteryInfo.EstimatedRunTime % 60
            Write-Host "  ║  Tiempo restante: $hours h $minutes min".PadRight(49) + "║" -ForegroundColor Cyan
        }
        
        Write-Host "  ║  Química: $($batteryInfo.Chemistry.PadRight(33)) ║" -ForegroundColor Cyan
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor Yellow
        
        Write-Log "Estado de batería: $($batteryInfo.EstimatedChargeRemaining)% - $($batteryInfo.BatteryStatus)" "INFO"
        
        return $batteryInfo
    }
    catch {
        Write-Host "  [✗] Error al obtener información de batería: $_" -ForegroundColor Red
        Write-Log "Error al obtener información de batería: $_" "ERROR"
        return $null
    }
}

function Get-BatteryHealth {
    <#
    .SYNOPSIS
        Genera reporte de salud de batería
    #>
    Write-Host "`n[*] Generando reporte de salud de batería..." -ForegroundColor Cyan
    
    $reportPath = "$env:TEMP\battery-report.html"
    
    try {
        powercfg /batteryreport /output $reportPath | Out-Null
        
        if (Test-Path $reportPath) {
            Write-Host "  [✓] Reporte generado: $reportPath" -ForegroundColor Green
            Write-Log "Reporte de batería generado" "SUCCESS"
            
            # Abrir en navegador
            $openReport = Read-Host "`n  ¿Abrir reporte en navegador? (S/N)"
            if ($openReport -eq 'S' -or $openReport -eq 's') {
                Start-Process $reportPath
            }
            
            return $reportPath
        }
    }
    catch {
        Write-Host "  [✗] Error al generar reporte: $_" -ForegroundColor Red
        Write-Log "Error al generar reporte de batería: $_" "ERROR"
    }
    
    return $null
}

function Get-PowerConsumption {
    <#
    .SYNOPSIS
        Analiza consumo de energía por componente
    #>
    Write-Host "`n[*] Analizando consumo de energía..." -ForegroundColor Cyan
    
    $consumption = @{
        CPU = 0
        GPU = 0
        Display = 0
        Disk = 0
        Network = 0
    }
    
    # CPU
    try {
        $cpu = Get-WmiObject -Class Win32_Processor
        $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        $consumption.CPU = [math]::Round($cpuLoad, 2)
        
        Write-Host "  [CPU] Uso: $($consumption.CPU)%" -ForegroundColor Cyan
    }
    catch { }
    
    # GPU
    try {
        $gpu = Get-WmiObject -Class Win32_VideoController
        Write-Host "  [GPU] $($gpu.Name)" -ForegroundColor Cyan
    }
    catch { }
    
    # Display
    try {
        $brightness = (Get-Ciminstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue).CurrentBrightness
        if ($brightness) {
            Write-Host "  [Pantalla] Brillo: $brightness%" -ForegroundColor Cyan
        }
    }
    catch { }
    
    # Procesos con mayor consumo
    Write-Host "`n  [*] Top 5 procesos con mayor consumo de CPU:" -ForegroundColor Yellow
    $topProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5
    
    foreach ($proc in $topProcesses) {
        $cpuTime = [math]::Round($proc.CPU, 2)
        Write-Host "      - $($proc.ProcessName): $cpuTime seg" -ForegroundColor Gray
    }
    
    return $consumption
}

function Get-SleepBlockers {
    <#
    .SYNOPSIS
        Detecta procesos que impiden la suspensión
    #>
    Write-Host "`n[*] Detectando procesos que impiden suspensión..." -ForegroundColor Cyan
    Write-Log "Analizando procesos que bloquean suspensión" "INFO"
    
    try {
        $requests = powercfg /requests
        
        Write-Host "`n  ╔════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║    PROCESOS QUE IMPIDEN SUSPENSIÓN             ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        
        $foundBlockers = $false
        
        foreach ($line in $requests) {
            if ($line -match '\[DRIVER\]||\[PROCESS\]||\[SERVICE\]') {
                Write-Host "  • $line" -ForegroundColor Yellow
                $foundBlockers = $true
            }
        }
        
        if (-not $foundBlockers) {
            Write-Host "  [✓] No se detectaron procesos bloqueadores" -ForegroundColor Green
        }
        else {
            Write-Host "`n  [!] Se recomienda cerrar estos procesos para permitir suspensión" -ForegroundColor Yellow
        }
        
        Write-Log "Análisis de bloqueadores completado" "INFO"
        return $requests
    }
    catch {
        Write-Host "  [✗] Error al detectar bloqueadores: $_" -ForegroundColor Red
        Write-Log "Error al detectar bloqueadores: $_" "ERROR"
        return $null
    }
}

function Set-PowerSettings {
    <#
    .SYNOPSIS
        Configura ajustes avanzados de energía
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Desktop", "Laptop", "Gaming")]
        [string]$DeviceType
    )
    
    Write-Host "`n[*] Aplicando configuración para: $DeviceType..." -ForegroundColor Cyan
    
    switch ($DeviceType) {
        "Desktop" {
            # Escritorio - Máximo rendimiento
            Write-Host "  [*] Configurando para escritorio..." -ForegroundColor Cyan
            
            powercfg /change monitor-timeout-ac 15
            powercfg /change standby-timeout-ac 30
            powercfg /change hibernate-timeout-ac 0
            
            Write-Host "  [✓] Monitor se apaga a los 15 min" -ForegroundColor Green
            Write-Host "  [✓] Suspensión a los 30 min" -ForegroundColor Green
            Write-Host "  [✓] Hibernación desactivada" -ForegroundColor Green
        }
        "Laptop" {
            # Portátil - Balance entre rendimiento y ahorro
            Write-Host "  [*] Configurando para portátil..." -ForegroundColor Cyan
            
            # En CA (conectado)
            powercfg /change monitor-timeout-ac 10
            powercfg /change standby-timeout-ac 20
            powercfg /change hibernate-timeout-ac 60
            
            # En batería
            powercfg /change monitor-timeout-dc 5
            powercfg /change standby-timeout-dc 10
            powercfg /change hibernate-timeout-dc 30
            
            Write-Host "  [✓] Configuración de CA aplicada" -ForegroundColor Green
            Write-Host "  [✓] Configuración de batería aplicada" -ForegroundColor Green
        }
        "Gaming" {
            # Gaming - Sin interrupciones
            Write-Host "  [*] Configurando modo gaming..." -ForegroundColor Cyan
            
            powercfg /change monitor-timeout-ac 0
            powercfg /change standby-timeout-ac 0
            powercfg /change hibernate-timeout-ac 0
            
            # Desactivar suspensión USB
            $activePlan = (powercfg /getactivescheme) -match 'GUID: ([a-f0-9-]+)'
            if ($matches) {
                $guid = $matches[1]
                powercfg /setacvalueindex $guid SUB_USB USBSELECTIVESUSPEND 0
                powercfg /setactive $guid
            }
            
            Write-Host "  [✓] Monitor siempre encendido" -ForegroundColor Green
            Write-Host "  [✓] Suspensión desactivada" -ForegroundColor Green
            Write-Host "  [✓] USB siempre activo" -ForegroundColor Green
        }
    }
    
    Write-Log "Configuración de energía aplicada para: $DeviceType" "SUCCESS"
}

function Show-EnergyReport {
    <#
    .SYNOPSIS
        Muestra un resumen completo del estado de energía
    #>
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              REPORTE COMPLETO DE ENERGÍA                     ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Plan actual
    $currentPlan = Get-PowerPlan
    Write-Host "`n[Plan Activo] $currentPlan" -ForegroundColor Green
    
    # Batería
    $battery = Get-BatteryStatus
    
    # Consumo
    Get-PowerConsumption | Out-Null
    
    # Bloqueadores
    Get-SleepBlockers | Out-Null
    
    Write-Host "`n══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 📊 Ver Planes de Energía                  ║" -ForegroundColor Cyan
        Write-Host "  ║  [2] 🔄 Cambiar Plan de Energía               ║" -ForegroundColor Green
        Write-Host "  ║  [3] ➕ Crear Plan Personalizado               ║" -ForegroundColor Magenta
        Write-Host "  ║  [4] 🔋 Estado de Batería                      ║" -ForegroundColor Yellow
        Write-Host "  ║  [5] 📈 Reporte de Salud de Batería            ║" -ForegroundColor Blue
        Write-Host "  ║  [6] ⚡ Analizar Consumo de Energía            ║" -ForegroundColor Cyan
        Write-Host "  ║  [7] 🚫 Ver Bloqueadores de Suspensión         ║" -ForegroundColor Red
        Write-Host "  ║  [8] ⚙️  Configuración Rápida                  ║" -ForegroundColor White
        Write-Host "  ║  [9] 📋 Reporte Completo                       ║" -ForegroundColor Green
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                Get-AvailablePowerPlans | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '2' {
                $plans = Get-AvailablePowerPlans
                
                Write-Host "`n  Ingrese el número del plan:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $plans.Count; $i++) {
                    Write-Host "  [$($i+1)] $($plans[$i].Name)" -ForegroundColor White
                }
                
                $selection = Read-Host "`n  Selección"
                
                if ([int]$selection -ge 1 -and [int]$selection -le $plans.Count) {
                    $selectedPlan = $plans[[int]$selection - 1]
                    Set-PowerPlan -PlanGUID $selectedPlan.GUID
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                Write-Host "`n  Tipos de perfil disponibles:" -ForegroundColor Cyan
                Write-Host "  [1] Máximo Rendimiento" -ForegroundColor Red
                Write-Host "  [2] Equilibrado" -ForegroundColor Yellow
                Write-Host "  [3] Ahorrador de Energía" -ForegroundColor Green
                Write-Host "  [4] Gaming" -ForegroundColor Magenta
                
                $profileType = Read-Host "`n  Seleccione tipo (1-4)"
                $planName = Read-Host "  Nombre del plan"
                
                $typeMap = @{
                    "1" = "MaxPerformance"
                    "2" = "Balanced"
                    "3" = "PowerSaver"
                    "4" = "Gaming"
                }
                
                if ($typeMap.ContainsKey($profileType) -and $planName) {
                    $newGuid = New-CustomPowerPlan -PlanName $planName -ProfileType $typeMap[$profileType]
                    
                    if ($newGuid) {
                        Write-Host "`n  ¿Activar este plan ahora? (S/N)" -ForegroundColor Cyan
                        $activate = Read-Host
                        
                        if ($activate -eq 'S' -or $activate -eq 's') {
                            Set-PowerPlan -PlanGUID $newGuid
                        }
                    }
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                Get-BatteryStatus | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                Get-BatteryHealth | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                Get-PowerConsumption | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '7' {
                Get-SleepBlockers | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '8' {
                Write-Host "`n  Seleccione tipo de dispositivo:" -ForegroundColor Cyan
                Write-Host "  [1] Escritorio (Desktop)" -ForegroundColor White
                Write-Host "  [2] Portátil (Laptop)" -ForegroundColor White
                Write-Host "  [3] Gaming" -ForegroundColor White
                
                $deviceType = Read-Host "`n  Selección (1-3)"
                
                $typeMap = @{
                    "1" = "Desktop"
                    "2" = "Laptop"
                    "3" = "Gaming"
                }
                
                if ($typeMap.ContainsKey($deviceType)) {
                    Set-PowerSettings -DeviceType $typeMap[$deviceType]
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '9' {
                Show-EnergyReport
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                Write-Host "`n  [✓] Saliendo del Gestor de Energía..." -ForegroundColor Green
                Write-Log "Gestor de Energía cerrado" "INFO"
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

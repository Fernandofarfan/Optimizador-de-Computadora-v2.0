<#
.SYNOPSIS
    Módulo de Análisis de Sistema
    Parte de Optimizador de Computadora v4.0.0
#>

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host "ANALIZADOR DE SISTEMA" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""
Write-Log "Iniciando análisis del sistema" -Level "INFO"

$reportePath = Join-Path $PSScriptRoot "Reporte-Sistema.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Seccion {
    param([string]$Titulo)
    Write-Host "`n-------------------------------------------" -ForegroundColor Yellow
    Write-Host " $Titulo" -ForegroundColor Yellow
    Write-Host "-------------------------------------------" -ForegroundColor Yellow
}

# Iniciar reporte
"═══════════════════════════════════════════════════" | Out-File $reportePath
"   REPORTE DE ANÁLISIS DEL SISTEMA" | Out-File $reportePath -Append
"   Generado: $timestamp" | Out-File $reportePath -Append
"═══════════════════════════════════════════════════`n" | Out-File $reportePath -Append

# ========================================
# 1. INFORMACIÓN DEL SISTEMA
# ========================================
Write-Seccion "1. INFORMACIÓN DEL SISTEMA"

$os = Get-WmiObject Win32_OperatingSystem
$cpu = Get-WmiObject Win32_Processor
$ram = Get-WmiObject Win32_ComputerSystem

$osInfo = @{
    Sistema = $os.Caption
    Version = $os.Version
    Arquitectura = $os.OSArchitecture
    UltimoInicio = $os.ConvertToDateTime($os.LastBootUpTime)
}

$cpuInfo = @{
    Procesador = $cpu.Name
    Nucleos = $cpu.NumberOfCores
    NucleosLogicos = $cpu.NumberOfLogicalProcessors
    VelocidadMaxMHz = $cpu.MaxClockSpeed
}

$ramTotalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$ramLibreGB = [math]::Round($os.FreePhysicalMemory / 1MB / 1024, 2)
$ramUsadaGB = [math]::Round($ramTotalGB - $ramLibreGB, 2)
$ramPorcentaje = [math]::Round(($ramUsadaGB / $ramTotalGB) * 100, 1)

Write-Host "  Sistema: " -NoNewline; Write-Host $osInfo.Sistema -ForegroundColor Green
Write-Host "  Procesador: " -NoNewline; Write-Host $cpuInfo.Procesador -ForegroundColor Green
Write-Host "  RAM Total: " -NoNewline; Write-Host "$ramTotalGB GB" -ForegroundColor Green
Write-Host "  RAM Usada: " -NoNewline; Write-Host "$ramUsadaGB GB ($ramPorcentaje%)" -ForegroundColor $(if($ramPorcentaje -gt 80){"Red"}else{"Green"})

"`n[INFORMACIÓN DEL SISTEMA]" | Out-File $reportePath -Append
"Sistema: $($osInfo.Sistema)" | Out-File $reportePath -Append
"Versión: $($osInfo.Version)" | Out-File $reportePath -Append
"Arquitectura: $($osInfo.Arquitectura)" | Out-File $reportePath -Append
"Último inicio: $($osInfo.UltimoInicio)" | Out-File $reportePath -Append
"Procesador: $($cpuInfo.Procesador)" | Out-File $reportePath -Append
"Núcleos: $($cpuInfo.Nucleos) físicos, $($cpuInfo.NucleosLogicos) lógicos" | Out-File $reportePath -Append
"RAM Total: $ramTotalGB GB" | Out-File $reportePath -Append
"RAM Usada: $ramUsadaGB GB ($ramPorcentaje%)" | Out-File $reportePath -Append

# ========================================
# 2. ANÁLISIS DE DISCOS
# ========================================
Write-Seccion "2. ANÁLISIS DE DISCOS"

$discos = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"

"`n[ANÁLISIS DE DISCOS]" | Out-File $reportePath -Append

foreach ($disco in $discos) {
    $totalGB = [math]::Round($disco.Size / 1GB, 2)
    $libreGB = [math]::Round($disco.FreeSpace / 1GB, 2)
    $usadoGB = [math]::Round($totalGB - $libreGB, 2)
    $porcentajeUsado = [math]::Round(($usadoGB / $totalGB) * 100, 1)
    
    Write-Host "`n  Disco: " -NoNewline; Write-Host "$($disco.DeviceID)" -ForegroundColor Cyan
    Write-Host "    Total: $totalGB GB"
    Write-Host "    Usado: $usadoGB GB ($porcentajeUsado%)" -ForegroundColor $(if($porcentajeUsado -gt 90){"Red"}elseif($porcentajeUsado -gt 75){"Yellow"}else{"Green"})
    Write-Host "    Libre: $libreGB GB"
    
    "`nDisco $($disco.DeviceID)" | Out-File $reportePath -Append
    "  Total: $totalGB GB" | Out-File $reportePath -Append
    "  Usado: $usadoGB GB ($porcentajeUsado%)" | Out-File $reportePath -Append
    "  Libre: $libreGB GB" | Out-File $reportePath -Append
    
    if ($porcentajeUsado -gt 90) {
        Write-Host "    ADVERTENCIA: Disco casi lleno!" -ForegroundColor Red
        "  ADVERTENCIA: Disco casi lleno!" | Out-File $reportePath -Append
    }
}

# ========================================
# 3. ARCHIVOS TEMPORALES
# ========================================
Write-Seccion "3. ARCHIVOS TEMPORALES"

"`n[ARCHIVOS TEMPORALES]" | Out-File $reportePath -Append

$tempPaths = @(
    $env:TEMP,
    "C:\Windows\Temp",
    "C:\Windows\Prefetch"
)

$totalTempMB = 0

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($size / 1MB, 2)
            $totalTempMB += $sizeMB
            
            Write-Host "  $path : " -NoNewline
            Write-Host "$sizeMB MB" -ForegroundColor $(if($sizeMB -gt 1000){"Red"}elseif($sizeMB -gt 500){"Yellow"}else{"Green"})
            
            "$path : $sizeMB MB" | Out-File $reportePath -Append
        } catch {
            Write-Host "  $path : No accesible" -ForegroundColor Gray
        }
    }
}

Write-Host "`n  Total archivos temporales: " -NoNewline
Write-Host "$totalTempMB MB" -ForegroundColor $(if($totalTempMB -gt 2000){"Red"}elseif($totalTempMB -gt 1000){"Yellow"}else{"Green"})

"`nTotal archivos temporales: $totalTempMB MB" | Out-File $reportePath -Append

# ========================================
# 4. PROCESOS CONSUMIENDO MÁS RECURSOS
# ========================================
Write-Seccion "4. PROCESOS QUE CONSUMEN MÁS RECURSOS"

"`n[TOP PROCESOS POR CPU]" | Out-File $reportePath -Append

Write-Host "`n  Top 10 procesos por CPU:" -ForegroundColor Cyan
$topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
foreach ($proc in $topCPU) {
    $cpuTime = [math]::Round($proc.CPU, 2)
    $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    Write-Host "    $($proc.Name): CPU=$cpuTime s, RAM=$memMB MB"
    "$($proc.Name): CPU=$cpuTime s, RAM=$memMB MB" | Out-File $reportePath -Append
}

"`n[TOP PROCESOS POR MEMORIA]" | Out-File $reportePath -Append

Write-Host "`n  Top 10 procesos por Memoria:" -ForegroundColor Cyan
$topMem = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10
foreach ($proc in $topMem) {
    $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    Write-Host "    $($proc.Name): $memMB MB"
    "$($proc.Name): $memMB MB" | Out-File $reportePath -Append
}

# ========================================
# 5. SERVICIOS INNECESARIOS
# ========================================
Write-Seccion "5. SERVICIOS QUE PUEDEN RALENTIZAR EL SISTEMA"

"`n[SERVICIOS INNECESARIOS]" | Out-File $reportePath -Append

# Lista de servicios que suelen ser innecesarios y consumen recursos
$serviciosInnecesarios = @(
    "DiagTrack",           # Telemetría
    "dmwappushservice",    # Mensajes WAP Push
    "WSearch",             # Windows Search (si no se usa)
    "SysMain",             # Superfetch
    "WerSvc",              # Reporte de errores
    "wuauserv",            # Windows Update (si se prefiere manual)
    "XblAuthManager",      # Xbox
    "XblGameSave",         # Xbox
    "XboxNetApiSvc"        # Xbox
)

$serviciosActivos = @()

foreach ($servicio in $serviciosInnecesarios) {
    $svc = Get-Service -Name $servicio -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        $serviciosActivos += $svc
        Write-Host "  - $($svc.DisplayName) - " -NoNewline
        Write-Host "ACTIVO" -ForegroundColor Yellow
        "$($svc.DisplayName) - ACTIVO (se puede desactivar)" | Out-File $reportePath -Append
    }
}

if ($serviciosActivos.Count -eq 0) {
    Write-Host "  No se encontraron servicios innecesarios activos" -ForegroundColor Green
}

# ========================================
# 6. PROGRAMAS DE INICIO
# ========================================
Write-Seccion "6. PROGRAMAS DE INICIO"

"`n[PROGRAMAS DE INICIO]" | Out-File $reportePath -Append

$startupItems = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location

Write-Host "  Total de programas en inicio: " -NoNewline
Write-Host $startupItems.Count -ForegroundColor $(if($startupItems.Count -gt 15){"Red"}elseif($startupItems.Count -gt 10){"Yellow"}else{"Green"})

"Total de programas en inicio: $($startupItems.Count)" | Out-File $reportePath -Append

foreach ($item in $startupItems) {
    Write-Host "    - $($item.Name)"
    "  - $($item.Name)" | Out-File $reportePath -Append
}

# ========================================
# 7. RENDIMIENTO DEL SISTEMA
# ========================================
Write-Seccion "7. RENDIMIENTO ACTUAL"

"`n[RENDIMIENTO DEL SISTEMA]" | Out-File $reportePath -Append

# Uso de CPU
$cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$cpuUsage = [math]::Round($cpuUsage, 1)

Write-Host "  Uso de CPU: " -NoNewline
Write-Host "$cpuUsage%" -ForegroundColor $(if($cpuUsage -gt 80){"Red"}elseif($cpuUsage -gt 60){"Yellow"}else{"Green"})

"Uso de CPU: $cpuUsage%" | Out-File $reportePath -Append
"Uso de RAM: $ramPorcentaje%" | Out-File $reportePath -Append

# Tiempo de actividad
$uptime = (Get-Date) - $osInfo.UltimoInicio
Write-Host "  Tiempo activo: $($uptime.Days) días, $($uptime.Hours) horas, $($uptime.Minutes) minutos"
"Tiempo activo: $($uptime.Days) días, $($uptime.Hours) horas" | Out-File $reportePath -Append

# ========================================
# 8. RECOMENDACIONES
# ========================================
Write-Seccion "8. RECOMENDACIONES"

"`n[RECOMENDACIONES]" | Out-File $reportePath -Append

$recomendaciones = @()

if ($ramPorcentaje -gt 80) {
    $recomendaciones += "RAM: Uso alto ($ramPorcentaje%). Considera cerrar programas o agregar más RAM."
}

if ($totalTempMB -gt 1000) {
    $recomendaciones += "Limpieza: $totalTempMB MB de archivos temporales pueden eliminarse."
}

if ($serviciosActivos.Count -gt 0) {
    $recomendaciones += "Servicios: $($serviciosActivos.Count) servicios innecesarios pueden desactivarse."
}

if ($startupItems.Count -gt 10) {
    $recomendaciones += "Inicio: $($startupItems.Count) programas en inicio. Reduce esta cantidad."
}

foreach ($disco in $discos) {
    $porcentaje = [math]::Round((($disco.Size - $disco.FreeSpace) / $disco.Size) * 100, 1)
    if ($porcentaje -gt 90) {
        $recomendaciones += "Disco $($disco.DeviceID): $porcentaje% lleno. Libera espacio urgentemente."
    } elseif ($porcentaje -gt 75) {
        $recomendaciones += "Disco $($disco.DeviceID): $porcentaje% lleno. Considera liberar espacio."
    }
}

if ($uptime.Days -gt 7) {
    $recomendaciones += "Sistema: Lleva $($uptime.Days) días sin reiniciar. Considera reiniciar."
}

if ($recomendaciones.Count -eq 0) {
    Write-Host "  Tu sistema está en buen estado" -ForegroundColor Green
    "Tu sistema está en buen estado" | Out-File $reportePath -Append
} else {
    foreach ($rec in $recomendaciones) {
        Write-Host "  $rec" -ForegroundColor Yellow
        $rec | Out-File $reportePath -Append
    }
}

# ========================================
# GUARDAR REPORTE
# ========================================
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✓ Análisis completo guardado en:" -ForegroundColor Green
Write-Host "    $reportePath" -ForegroundColor White
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Log "Análisis del sistema completado exitosamente" -Level "SUCCESS"
Write-Log "Reporte guardado en: $reportePath" -Level "INFO"

# Retornar datos para usar en optimizaciones
return @{
    LimpiarTemporales = $totalTempMB -gt 500
    DesactivarServicios = $serviciosActivos.Count -gt 0
    OptimizarInicio = $startupItems.Count -gt 10
    RAMAlta = $ramPorcentaje -gt 80
    DiscoLleno = ($discos | Where-Object { (($_.Size - $_.FreeSpace) / $_.Size) * 100 -gt 90 }).Count -gt 0
    Recomendaciones = $recomendaciones
}

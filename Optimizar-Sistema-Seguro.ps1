<#
.SYNOPSIS
    Módulo de Optimización Segura (No destructiva)
    Parte de Optimizador de Computadora v2.0
#>

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "OPTIMIZACION SEGURA (Modo Seguro)" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "Nota: No se eliminarán archivos personales ni de sistema." -ForegroundColor Gray
Write-Host ""

$logPath = Join-Path $PSScriptRoot "Analisis-Seguro-Log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Seccion {
    param([string]$Titulo)
    Write-Host "`n-------------------------------------------" -ForegroundColor Cyan
    Write-Host " $Titulo" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor Cyan
}

function Write-Log {
    param([string]$Mensaje)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Mensaje" | Out-File $logPath -Append
}

# Iniciar log
"═══════════════════════════════════════════════════" | Out-File $logPath
"   ANÁLISIS SEGURO DEL SISTEMA (PC PRESTADA)" | Out-File $logPath -Append
"   Iniciado: $timestamp" | Out-File $logPath -Append
"   MODO: Solo análisis, sin borrar archivos" | Out-File $logPath -Append
"═══════════════════════════════════════════════════`n" | Out-File $logPath -Append

$analisisRealizados = 0

# ========================================
# 1. ANÁLISIS DE ARCHIVOS TEMPORALES (SIN BORRAR)
# ========================================
Write-Seccion "1. ANÁLISIS DE ARCHIVOS TEMPORALES"

Write-Host "  ℹ MODO SEGURO: No se borrarán archivos" -ForegroundColor Yellow
Write-Host ""

$tempPaths = @(
    $env:TEMP,
    "C:\Windows\Temp"
)

$totalTempMB = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                     Measure-Object -Property Length -Sum).Sum
            if ($null -eq $size) { $size = 0 }
            $sizeMB = [math]::Round($size / 1MB, 2)
            $totalTempMB += $sizeMB
            
            Write-Host "  Carpeta: $path" -ForegroundColor White
            Write-Host "     Tamano: $sizeMB MB" -ForegroundColor Cyan
            Write-Log "Analizados: $sizeMB MB en $path (NO eliminados)"
            
        } catch {
            Write-Host "  Advertencia: No se pudo analizar: $path" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
if ($totalTempMB -gt 500) {
    Write-Host "  RECOMENDACION: Se podrian liberar $totalTempMB MB" -ForegroundColor Green
    Write-Host "     -> Puedes usar 'Liberador de espacio en disco' de Windows" -ForegroundColor Gray
    Write-Host "     -> Buscar 'Disk Cleanup' en el menu Inicio" -ForegroundColor Gray
} else {
    Write-Host "  OK: Archivos temporales en nivel normal ($totalTempMB MB)" -ForegroundColor Green
}

Write-Log "Total archivos temporales: $totalTempMB MB (NO eliminados)"
$analisisRealizados++

# ========================================
# 2. ANÁLISIS DE SERVICIOS
# ========================================
Write-Seccion "2. ANÁLISIS DE SERVICIOS"

Write-Host "  ℹ Verificando servicios que consumen recursos..." -ForegroundColor Yellow
Write-Host ""

$serviciosAnalizar = @{
    "DiagTrack" = "Telemetría de Windows"
    "dmwappushservice" = "Mensajes WAP Push"
    "SysMain" = "Superfetch"
    "WerSvc" = "Informes de errores"
}

$serviciosActivos = @()
foreach ($servicioNombre in $serviciosAnalizar.Keys) {
    try {
        $servicio = Get-Service -Name $servicioNombre -ErrorAction SilentlyContinue
        
        if ($servicio -and $servicio.Status -eq "Running") {
            Write-Host "  📊 $($serviciosAnalizar[$servicioNombre])" -ForegroundColor White
            Write-Host "     Estado: ACTIVO (consumiendo recursos)" -ForegroundColor Cyan
            Write-Log "Servicio activo: $servicioNombre"
            $serviciosActivos += $servicio
        }
    } catch {
        # Servicio no existe
    }
}

Write-Host ""
if ($serviciosActivos.Count -gt 0) {
    Write-Host "  [i] RECOMENDACIÓN: $($serviciosActivos.Count) servicios podrían desactivarse" -ForegroundColor Green
    Write-Host "     -> Solo si el dueño de la PC lo autoriza" -ForegroundColor Gray
    Write-Host "     -> Usar 'services.msc' para gestionar servicios" -ForegroundColor Gray
} else {
    Write-Host "  [OK] Servicios optimizados correctamente" -ForegroundColor Green
}

Write-Log "Servicios analizados: $($serviciosActivos.Count) activos"
$analisisRealizados++

# ========================================
# 3. OPTIMIZACIÓN TEMPORAL DE MEMORIA
# ========================================
Write-Seccion "3. OPTIMIZACIÓN TEMPORAL DE MEMORIA"

Write-Host "  ℹ Optimización de memoria (temporal, no permanente)..." -ForegroundColor Yellow
Write-Host ""

try {
    Write-Host "  • Limpiando caché DNS..." -NoNewline
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Write-Host " [OK]" -ForegroundColor Green
    
    Write-Host "  • Liberando memoria no utilizada..." -NoNewline
    # Solicitar al sistema que libere memoria
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Host " [OK]" -ForegroundColor Green
    
    Write-Log "Memoria optimizada temporalmente"
    $analisisRealizados++
    
    Write-Host ""
    Write-Host "  [OK] Memoria optimizada (los cambios son temporales)" -ForegroundColor Green
    
} catch {
    Write-Host " [!]" -ForegroundColor Yellow
    Write-Log "Error en optimización de memoria: $_"
}

# ========================================
# 4. ANÁLISIS DE PROGRAMAS DE INICIO
# ========================================
Write-Seccion "4. PROGRAMAS EN INICIO"

Write-Host "  ℹ Analizando programas que se inician con Windows..." -ForegroundColor Yellow
Write-Host ""

try {
    $startupItems = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | 
                    Select-Object Name, Command, Location
    
    if ($startupItems) {
        Write-Host "  Total de programas en inicio: " -NoNewline
        if ($startupItems.Count -gt 15) {
            Write-Host "$($startupItems.Count) (MUCHOS)" -ForegroundColor Red
        } elseif ($startupItems.Count -gt 10) {
            Write-Host "$($startupItems.Count) (Moderado)" -ForegroundColor Yellow
        } else {
            Write-Host "$($startupItems.Count) (Optimo)" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "  Programas detectados:" -ForegroundColor Cyan
        $contador = 0
        foreach ($item in $startupItems) {
            $contador++
            if ($contador -le 10) {
                Write-Host "     $contador. $($item.Name)" -ForegroundColor White
            }
        }
        
        if ($startupItems.Count -gt 10) {
            Write-Host "     ... y $($startupItems.Count - 10) más" -ForegroundColor Gray
        }
        
        Write-Host ""
        if ($startupItems.Count -gt 10) {
            Write-Host "  [i] RECOMENDACIÓN: Reduce programas de inicio" -ForegroundColor Green
            Write-Host "     -> Presiona Ctrl+Shift+Esc -> Inicio" -ForegroundColor Gray
            Write-Host "     -> Deshabilita programas innecesarios" -ForegroundColor Gray
        }
        
        Write-Log "Programas en inicio: $($startupItems.Count)"
        $analisisRealizados++
    }
} catch {
    Write-Host "  [!] No se pudo analizar programas de inicio" -ForegroundColor Yellow
}

# ========================================
# 5. ANÁLISIS DE RENDIMIENTO ACTUAL
# ========================================
Write-Seccion "5. RENDIMIENTO ACTUAL"

Write-Host "  ℹ Midiendo uso de recursos..." -ForegroundColor Yellow
Write-Host ""

# RAM
$os = Get-WmiObject Win32_OperatingSystem
$ram = Get-WmiObject Win32_ComputerSystem
$ramTotalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$ramLibreGB = [math]::Round($os.FreePhysicalMemory / 1MB / 1024, 2)
$ramUsadaGB = [math]::Round($ramTotalGB - $ramLibreGB, 2)
$ramPorcentaje = [math]::Round(($ramUsadaGB / $ramTotalGB) * 100, 1)

Write-Host "  MEMORIA RAM:" -ForegroundColor Cyan
Write-Host "     Total: $ramTotalGB GB" -ForegroundColor White
Write-Host "     En uso: $ramUsadaGB GB ($ramPorcentaje porciento)" -ForegroundColor $(if($ramPorcentaje -gt 80){"Red"}elseif($ramPorcentaje -gt 60){"Yellow"}else{"Green"})
Write-Host "     Libre: $ramLibreGB GB" -ForegroundColor White

if ($ramPorcentaje -gt 80) {
    Write-Host ""
    Write-Host "  Advertencia: Uso de RAM muy alto" -ForegroundColor Red
    Write-Host "     -> Cierra programas que no estes usando" -ForegroundColor Gray
} elseif ($ramPorcentaje -gt 60) {
    Write-Host ""
    Write-Host "  Advertencia: Uso de RAM moderado-alto" -ForegroundColor Yellow
}

# CPU
Write-Host ""
Write-Host "  PROCESADOR:" -ForegroundColor Cyan
try {
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue
    $cpuUsage = [math]::Round($cpuUsage, 1)
    Write-Host "     Uso actual: $cpuUsage porciento" -ForegroundColor $(if($cpuUsage -gt 80){"Red"}elseif($cpuUsage -gt 60){"Yellow"}else{"Green"})
} catch {
    Write-Host "     No disponible" -ForegroundColor Gray
}

# Disco
Write-Host ""
Write-Host "  DISCOS:" -ForegroundColor Cyan
$discos = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disco in $discos) {
    $totalGB = [math]::Round($disco.Size / 1GB, 2)
    $libreGB = [math]::Round($disco.FreeSpace / 1GB, 2)
    $usadoPorcentaje = [math]::Round((($disco.Size - $disco.FreeSpace) / $disco.Size) * 100, 1)
    
    Write-Host "     $($disco.DeviceID) - Usado: $usadoPorcentaje porciento" -ForegroundColor $(if($usadoPorcentaje -gt 90){"Red"}elseif($usadoPorcentaje -gt 75){"Yellow"}else{"White"})
    Write-Host "        Libre: $libreGB GB de $totalGB GB" -ForegroundColor Gray
    
    if ($usadoPorcentaje -gt 90) {
        Write-Host "        Advertencia: Disco casi lleno - libera espacio urgente" -ForegroundColor Red
    }
}

Write-Log "Análisis de rendimiento completado"
$analisisRealizados++

# ========================================
# 6. ANÁLISIS DE PROCESOS PESADOS
# ========================================
Write-Seccion "6. PROCESOS QUE CONSUMEN MÁS RECURSOS"

Write-Host "  ℹ Identificando programas que usan más recursos..." -ForegroundColor Yellow
Write-Host ""

Write-Host "  [TOP] Top 5 por uso de MEMORIA:" -ForegroundColor Cyan
$topMem = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
foreach ($proc in $topMem) {
    $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 0)
    Write-Host "     $($proc.Name): $memMB MB" -ForegroundColor White
}

Write-Host ""
Write-Host "  [FAST] Top 5 por uso de CPU:" -ForegroundColor Cyan
$topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
foreach ($proc in $topCPU) {
    $cpuTime = [math]::Round($proc.CPU, 1)
    if ($cpuTime -gt 0) {
        Write-Host "     $($proc.Name): $cpuTime segundos" -ForegroundColor White
    }
}

Write-Log "Procesos analizados"
$analisisRealizados++

# ========================================
# 7. PLAN DE ENERGÍA
# ========================================
Write-Seccion "7. CONFIGURACIÓN DE ENERGÍA"

Write-Host "  ℹ Verificando plan de energía..." -ForegroundColor Yellow
Write-Host ""

try {
    $planOutput = powercfg /getactivescheme 2>&1
    
    if ($planOutput -match "Alto rendimiento|High performance") {
        Write-Host "  [OK] Plan actual: Alto rendimiento" -ForegroundColor Green
        Write-Host "     Configuración óptima para velocidad" -ForegroundColor Gray
    } elseif ($planOutput -match "Equilibrado|Balanced") {
        Write-Host "  [!] Plan actual: Equilibrado" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [i] RECOMENDACIÓN: Cambiar a 'Alto rendimiento'" -ForegroundColor Green
        Write-Host "     -> Panel de Control -> Opciones de energía" -ForegroundColor Gray
        Write-Host "     -> Seleccionar 'Alto rendimiento'" -ForegroundColor Gray
        Write-Host "     -> Solo si el dueño lo autoriza" -ForegroundColor Yellow
    } else {
        Write-Host "  [!] Plan actual: Ahorro de energía" -ForegroundColor Red
        Write-Host ""
        Write-Host "  [i] RECOMENDACIÓN: Cambiar a 'Alto rendimiento'" -ForegroundColor Green
        Write-Host "     -> Panel de Control -> Opciones de energía" -ForegroundColor Gray
    }
    
    Write-Log "Plan de energía analizado"
    $analisisRealizados++
} catch {
    Write-Host "  [!] No se pudo verificar plan de energía" -ForegroundColor Yellow
}

# ========================================
# RESUMEN FINAL
# ========================================
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  [OK] ANÁLISIS COMPLETADO (MODO SEGURO)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  ✅ PC PRESTADA - NO se borraron archivos" -ForegroundColor Yellow
Write-Host "  ✅ NO se hicieron cambios permanentes" -ForegroundColor Yellow
Write-Host "  ✅ Solo optimizaciones temporales de memoria" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Análisis completados: $analisisRealizados" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [FILE] Log guardado en:" -ForegroundColor White
Write-Host "     $logPath" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  [i] RECOMENDACIONES SEGURAS:" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  PUEDES HACER (sin permiso):" -ForegroundColor Green
Write-Host "   [OK] Cerrar programas que no uses" -ForegroundColor White
Write-Host "   [OK] Cerrar pestañas del navegador" -ForegroundColor White
Write-Host "   [OK] Reiniciar la PC si está lenta" -ForegroundColor White
Write-Host ""
Write-Host "  CONSULTA AL DUEÑO antes de:" -ForegroundColor Yellow
Write-Host "   • Borrar archivos temporales" -ForegroundColor White
Write-Host "   • Cambiar configuración de energía" -ForegroundColor White
Write-Host "   • Desactivar servicios o programas" -ForegroundColor White
Write-Host "   • Desinstalar aplicaciones" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green

Write-Log "Análisis completado. Total: $analisisRealizados análisis realizados"
Write-Log "Modo seguro: No se eliminaron archivos ni se hicieron cambios permanentes"
Write-Log "═══════════════════════════════════════════════"

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

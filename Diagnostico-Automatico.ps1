# ============================================
# Diagnostico-Automatico.ps1
# Detección automática de problemas del sistema
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DIAGNÓSTICO AUTOMÁTICO DEL SISTEMA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando diagnóstico automático" -Level "INFO"

$problemas = @()
$advertencias = @()

# 1. DISCO LLENO
Write-Host "[1/8] Verificando espacio en disco..." -ForegroundColor Cyan
$discoC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$porcentajeLibre = [math]::Round(($discoC.FreeSpace / $discoC.Size) * 100, 1)

if ($porcentajeLibre -lt 10) {
    $problemas += "❌ CRÍTICO: Disco C: casi lleno ($porcentajeLibre% libre)"
    Write-Host "  ❌ Disco C: casi lleno ($porcentajeLibre% libre)" -ForegroundColor Red
} elseif ($porcentajeLibre -lt 20) {
    $advertencias += "⚠️  Disco C: poco espacio ($porcentajeLibre% libre)"
    Write-Host "  ⚠️  Disco C: poco espacio ($porcentajeLibre% libre)" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Espacio en disco: OK ($porcentajeLibre% libre)" -ForegroundColor Green
}

# 2. RAM EXCESIVA
Write-Host "[2/8] Verificando uso de RAM..." -ForegroundColor Cyan
$os = Get-WmiObject Win32_OperatingSystem
$ramUsada = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)

if ($ramUsada -gt 90) {
    $problemas += "❌ CRÍTICO: Uso de RAM muy alto ($ramUsada%)"
    Write-Host "  ❌ RAM muy alta ($ramUsada%)" -ForegroundColor Red
} elseif ($ramUsada -gt 80) {
    $advertencias += "⚠️  Uso de RAM elevado ($ramUsada%)"
    Write-Host "  ⚠️  RAM elevada ($ramUsada%)" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Uso de RAM: OK ($ramUsada%)" -ForegroundColor Green
}

# 3. CPU SOSTENIDA
Write-Host "[3/8] Verificando uso de CPU..." -ForegroundColor Cyan
$cpu1 = (Get-WmiObject Win32_Processor).LoadPercentage
Start-Sleep -Seconds 2
$cpu2 = (Get-WmiObject Win32_Processor).LoadPercentage
$cpuPromedio = [math]::Round(($cpu1 + $cpu2) / 2, 0)

if ($cpuPromedio -gt 80) {
    $advertencias += "⚠️  CPU con uso sostenido alto ($cpuPromedio%)"
    Write-Host "  ⚠️  CPU alta ($cpuPromedio%)" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Uso de CPU: OK ($cpuPromedio%)" -ForegroundColor Green
}

# 4. SERVICIOS CRÍTICOS CAÍDOS
Write-Host "[4/8] Verificando servicios críticos..." -ForegroundColor Cyan
$serviciosCriticos = @("WinDefend", "mpssvc", "wuauserv", "EventLog")
$serviciosCaidos = @()

foreach ($svc in $serviciosCriticos) {
    $servicio = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($servicio -and $servicio.Status -ne "Running") {
        $serviciosCaidos += $svc
    }
}

if ($serviciosCaidos.Count -gt 0) {
    $problemas += "❌ CRÍTICO: Servicios caídos: $($serviciosCaidos -join ', ')"
    Write-Host "  ❌ Servicios caídos: $($serviciosCaidos -join ', ')" -ForegroundColor Red
} else {
    Write-Host "  ✅ Servicios críticos: OK" -ForegroundColor Green
}

# 5. PROGRAMAS EN INICIO EXCESIVOS
Write-Host "[5/8] Verificando programas en inicio..." -ForegroundColor Cyan
$startupCount = (Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Count

if ($startupCount -gt 20) {
    $advertencias += "⚠️  Muchos programas en inicio ($startupCount)"
    Write-Host "  ⚠️  Muchos programas en inicio ($startupCount)" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Programas en inicio: OK ($startupCount)" -ForegroundColor Green
}

# 6. WINDOWS DEFENDER
Write-Host "[6/8] Verificando Windows Defender..." -ForegroundColor Cyan
try {
    $defender = Get-MpComputerStatus
    if (-not $defender.RealTimeProtectionEnabled) {
        $problemas += "❌ CRÍTICO: Windows Defender desactivado"
        Write-Host "  ❌ Defender desactivado" -ForegroundColor Red
    } else {
        Write-Host "  ✅ Windows Defender: OK" -ForegroundColor Green
    }
} catch {
    $advertencias += "⚠️  No se pudo verificar Defender"
    Write-Host "  ⚠️  No se pudo verificar Defender" -ForegroundColor Yellow
}

# 7. ACTUALIZACIONES PENDIENTES
Write-Host "[7/8] Verificando actualizaciones..." -ForegroundColor Cyan
try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
    $pendientes = $searchResult.Updates.Count
    
    if ($pendientes -gt 10) {
        $advertencias += "⚠️  Muchas actualizaciones pendientes ($pendientes)"
        Write-Host "  ⚠️  Actualizaciones pendientes: $pendientes" -ForegroundColor Yellow
    } else {
        Write-Host "  ✅ Actualizaciones: $pendientes pendientes" -ForegroundColor Green
    }
} catch {
    Write-Host "  ℹ️  No se pudo verificar actualizaciones" -ForegroundColor Gray
}

# 8. TEMPERATURA (básico)
Write-Host "[8/8] Verificando estado general..." -ForegroundColor Cyan
$procesosAltos = Get-Process | Where-Object { $_.WorkingSet -gt 500MB } | Measure-Object
if ($procesosAltos.Count -gt 5) {
    $advertencias += "⚠️  Varios procesos con alto consumo de RAM"
    Write-Host "  ⚠️  $($procesosAltos.Count) procesos con alta RAM" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Procesos: OK" -ForegroundColor Green
}

Write-Host ""

# RESUMEN
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESUMEN DEL DIAGNÓSTICO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($problemas.Count -eq 0 -and $advertencias.Count -eq 0) {
    Write-Host "✅ EXCELENTE: No se detectaron problemas" -ForegroundColor Green
    Write-Log "Diagnóstico: Sin problemas detectados" -Level "SUCCESS"
} else {
    if ($problemas.Count -gt 0) {
        Write-Host "❌ PROBLEMAS CRÍTICOS DETECTADOS:" -ForegroundColor Red
        foreach ($p in $problemas) {
            Write-Host "  $p" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($advertencias.Count -gt 0) {
        Write-Host "⚠️  ADVERTENCIAS:" -ForegroundColor Yellow
        foreach ($a in $advertencias) {
            Write-Host "  $a" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "💡 SOLUCIONES RECOMENDADAS:" -ForegroundColor Cyan
    
    if ($porcentajeLibre -lt 20) {
        Write-Host "  • Ejecuta Limpieza Profunda para liberar espacio" -ForegroundColor White
    }
    if ($ramUsada -gt 80) {
        Write-Host "  • Cierra programas innecesarios o amplía RAM" -ForegroundColor White
    }
    if ($startupCount -gt 20) {
        Write-Host "  • Usa Gestionar Inicio para desactivar programas" -ForegroundColor White
    }
    if ($serviciosCaidos.Count -gt 0) {
        Write-Host "  • Inicia los servicios caídos manualmente" -ForegroundColor White
    }
    
    Write-Log "Diagnóstico: $($problemas.Count) problemas, $($advertencias.Count) advertencias" -Level "WARNING"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

# ============================================
# Revertir-Cambios.ps1
# Revierte optimizaciones y restaura configuración original
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REVERTIR OPTIMIZACIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando proceso de reversión de cambios" -Level "INFO"

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Log "Intento de revertir sin permisos de admin" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit 1
}

Write-Host "Este script te permite revertir cambios realizados por el optimizador." -ForegroundColor Yellow
Write-Host ""

# ============================================
# 1. SERVICIOS DESHABILITADOS
# ============================================

Write-Host "[1/4] Analizando servicios deshabilitados..." -ForegroundColor Cyan
Write-Host ""

$serviciosOptimizados = @(
    "DiagTrack",           # Telemetría
    "SysMain",             # Superfetch
    "WSearch",             # Windows Search
    "RemoteRegistry",      # Registro remoto
    "WerSvc",              # Reporte de errores
    "XblAuthManager",      # Xbox
    "XblGameSave",         # Xbox
    "XboxNetApiSvc"        # Xbox
)

$serviciosDeshabilitados = @()

foreach ($svcName in $serviciosOptimizados) {
    $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    
    if ($service) {
        if ($service.StartType -eq "Disabled") {
            $serviciosDeshabilitados += @{
                Nombre = $svcName
                DisplayName = $service.DisplayName
                Status = $service.Status
            }
            Write-Host "  ⚠️  $svcName - Deshabilitado" -ForegroundColor Yellow
        } else {
            Write-Host "  ✅ $svcName - Ya está activo ($($service.StartType))" -ForegroundColor Green
        }
    }
}

if ($serviciosDeshabilitados.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ No hay servicios deshabilitados por el optimizador" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "¿Deseas reactivar estos $($serviciosDeshabilitados.Count) servicios? (S/N): " -NoNewline
    $response = Read-Host
    
    if ($response -eq "S" -or $response -eq "s") {
        Write-Host ""
        Write-Host "Reactivando servicios..." -ForegroundColor Yellow
        
        foreach ($svc in $serviciosDeshabilitados) {
            try {
                Set-Service -Name $svc.Nombre -StartupType Manual -ErrorAction Stop
                Write-Host "  ✅ $($svc.Nombre) - Configurado como Manual" -ForegroundColor Green
                Write-Log "Servicio $($svc.Nombre) reactivado (Manual)" -Level "SUCCESS"
            } catch {
                Write-Host "  ❌ Error al reactivar $($svc.Nombre)" -ForegroundColor Red
                Write-Log "Error al reactivar $($svc.Nombre): $($_.Exception.Message)" -Level "ERROR"
            }
        }
        
        Write-Host ""
        Write-Host "¿Deseas iniciar estos servicios ahora? (S/N): " -NoNewline
        $startResponse = Read-Host
        
        if ($startResponse -eq "S" -or $startResponse -eq "s") {
            foreach ($svc in $serviciosDeshabilitados) {
                try {
                    Start-Service -Name $svc.Nombre -ErrorAction Stop
                    Write-Host "  ✅ $($svc.Nombre) - Iniciado" -ForegroundColor Green
                    Write-Log "Servicio $($svc.Nombre) iniciado" -Level "SUCCESS"
                } catch {
                    Write-Host "  ⚠️  $($svc.Nombre) - No se pudo iniciar (puede requerir dependencias)" -ForegroundColor Yellow
                    Write-Log "No se pudo iniciar $($svc.Nombre): $($_.Exception.Message)" -Level "WARNING"
                }
            }
        }
    }
}

Write-Host ""

# ============================================
# 2. PUNTOS DE RESTAURACIÓN
# ============================================

Write-Host "[2/4] Verificando puntos de restauración..." -ForegroundColor Cyan
Write-Host ""

try {
    $restorePoints = Get-ComputerRestorePoint -ErrorAction Stop | 
                     Where-Object { $_.Description -like "*PC Optimizer*" } |
                     Sort-Object CreationTime -Descending |
                     Select-Object -First 5
    
    if ($restorePoints) {
        Write-Host "Puntos de restauración creados por el optimizador:" -ForegroundColor White
        Write-Host ""
        
        $i = 1
        foreach ($point in $restorePoints) {
            $date = $point.CreationTime.ToString("yyyy-MM-dd HH:mm")
            Write-Host "  [$i] $date - $($point.Description)" -ForegroundColor Gray
            $i++
        }
        
        Write-Host ""
        Write-Host "💡 Para restaurar tu PC a un punto anterior:" -ForegroundColor Yellow
        Write-Host "   1. Busca 'Crear punto de restauración' en Windows" -ForegroundColor White
        Write-Host "   2. Haz clic en 'Restaurar sistema'" -ForegroundColor White
        Write-Host "   3. Selecciona uno de los puntos listados arriba" -ForegroundColor White
        Write-Log "Usuario consultó puntos de restauración disponibles" -Level "INFO"
    } else {
        Write-Host "No se encontraron puntos de restauración del optimizador" -ForegroundColor Gray
    }
} catch {
    Write-Host "No se pudo acceder a puntos de restauración" -ForegroundColor Gray
    Write-Log "Error al acceder a restore points: $($_.Exception.Message)" -Level "WARNING"
}

Write-Host ""

# ============================================
# 3. LOGS Y REPORTES
# ============================================

Write-Host "[3/4] Limpieza de logs y reportes..." -ForegroundColor Cyan
Write-Host ""

$logsPath = Join-Path $scriptPath "logs"
$reportes = Get-ChildItem -Path $scriptPath -Filter "Reporte-*.txt" -ErrorAction SilentlyContinue

$logFiles = @()
if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" -ErrorAction SilentlyContinue
}

$totalSize = 0
if ($logFiles) {
    $totalSize += ($logFiles | Measure-Object -Property Length -Sum).Sum / 1MB
}
if ($reportes) {
    $totalSize += ($reportes | Measure-Object -Property Length -Sum).Sum / 1MB
}

Write-Host "Logs encontrados: $($logFiles.Count)" -ForegroundColor White
Write-Host "Reportes encontrados: $($reportes.Count)" -ForegroundColor White
Write-Host "Espacio total: $([math]::Round($totalSize, 2)) MB" -ForegroundColor White
Write-Host ""

if ($logFiles.Count -gt 0 -or $reportes.Count -gt 0) {
    Write-Host "¿Deseas eliminar logs y reportes? (S/N): " -NoNewline
    $response = Read-Host
    
    if ($response -eq "S" -or $response -eq "s") {
        $deleted = 0
        
        foreach ($log in $logFiles) {
            Remove-Item -Path $log.FullName -Force -ErrorAction SilentlyContinue
            $deleted++
        }
        
        foreach ($reporte in $reportes) {
            Remove-Item -Path $reporte.FullName -Force -ErrorAction SilentlyContinue
            $deleted++
        }
        
        Write-Host "✅ $deleted archivo(s) eliminado(s)" -ForegroundColor Green
        Write-Log "Logs y reportes limpiados: $deleted archivos, $([math]::Round($totalSize, 2)) MB" -Level "INFO"
    }
} else {
    Write-Host "✅ No hay logs o reportes para limpiar" -ForegroundColor Green
}

Write-Host ""

# ============================================
# 4. CONFIGURACIÓN DEL SISTEMA
# ============================================

Write-Host "[4/4] Información adicional..." -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Estado actual del sistema:" -ForegroundColor Yellow
Write-Host "  • RAM: $(Get-WmiObject Win32_OperatingSystem | ForEach-Object { [math]::Round($_.TotalVisibleMemorySize / 1MB, 2) }) GB" -ForegroundColor White

$freeSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | ForEach-Object { [math]::Round($_.FreeSpace / 1GB, 2) }
Write-Host "  • Espacio libre C: $freeSpace GB" -ForegroundColor White

$startupPrograms = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Measure-Object
Write-Host "  • Programas en inicio: $($startupPrograms.Count)" -ForegroundColor White

Write-Host ""
Write-Host "📝 Recomendaciones:" -ForegroundColor Yellow
Write-Host "  • Si experimentas problemas después de optimizar, usa un punto de restauración" -ForegroundColor White
Write-Host "  • Los servicios reactivados se configuran como 'Manual' (no automáticos)" -ForegroundColor White
Write-Host "  • Puedes volver a optimizar en cualquier momento ejecutando el script principal" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REVERSIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Proceso de reversión completado" -Level "SUCCESS"

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

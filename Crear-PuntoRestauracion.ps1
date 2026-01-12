# ============================================
# Crear-PuntoRestauracion.ps1
# Crea un punto de restauración antes de cambios críticos
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CREACIÓN DE PUNTO DE RESTAURACIÓN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Log "Intento de crear punto de restauración sin permisos de admin" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
    Read-Host
    exit 1
}

# Verificar si System Restore está habilitado
Write-Host "Verificando configuración de System Restore..." -ForegroundColor Yellow
Write-Log "Verificando estado de System Restore" -Level "INFO"

try {
    $restorePoints = Get-ComputerRestorePoint -ErrorAction Stop
    Write-Host "✅ System Restore está habilitado" -ForegroundColor Green
    Write-Log "System Restore está habilitado" -Level "SUCCESS"
} catch {
    Write-Host "⚠️  System Restore parece estar deshabilitado" -ForegroundColor Yellow
    Write-Log "System Restore no está habilitado o no es accesible" -Level "WARNING"
    Write-Host ""
    Write-Host "¿Deseas intentar habilitarlo? (S/N): " -NoNewline
    $response = Read-Host
    
    if ($response -eq "S" -or $response -eq "s") {
        try {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
            Write-Host "✅ System Restore habilitado en C:" -ForegroundColor Green
            Write-Log "System Restore habilitado en C:" -Level "SUCCESS"
        } catch {
            Write-Host "❌ No se pudo habilitar System Restore" -ForegroundColor Red
            Write-Log "Error al habilitar System Restore: $($_.Exception.Message)" -Level "ERROR"
            exit 1
        }
    } else {
        Write-Host "Operación cancelada" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""

# Verificar espacio disponible
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)

if ($freeSpaceGB -lt 5) {
    Write-Host "⚠️  Advertencia: Espacio en disco bajo ($freeSpaceGB GB)" -ForegroundColor Yellow
    Write-Host "   Se recomienda al menos 5 GB libres para puntos de restauración" -ForegroundColor Gray
    Write-Log "Advertencia: Espacio en disco bajo ($freeSpaceGB GB)" -Level "WARNING"
    Write-Host ""
    Write-Host "¿Continuar de todos modos? (S/N): " -NoNewline
    $response = Read-Host
    if ($response -ne "S" -and $response -ne "s") {
        Write-Host "Operación cancelada" -ForegroundColor Yellow
        exit 0
    }
}

# Crear punto de restauración
Write-Host "Creando punto de restauración..." -ForegroundColor Yellow
Write-Host "(Esto puede tomar 1-3 minutos)" -ForegroundColor Gray
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$description = "PC Optimizer v2.1 - Backup antes de optimización ($timestamp)"

try {
    Write-Log "Iniciando creación de punto de restauración: $description" -Level "INFO"
    
    # Crear el punto de restauración
    Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    
    Write-Host "✅ Punto de restauración creado exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Descripción: $description" -ForegroundColor White
    Write-Log "Punto de restauración creado: $description" -Level "SUCCESS"
    
    # Mostrar puntos de restauración recientes
    Write-Host ""
    Write-Host "Puntos de restauración recientes:" -ForegroundColor Cyan
    $recentPoints = Get-ComputerRestorePoint | Select-Object -Last 5 | Sort-Object CreationTime -Descending
    
    foreach ($point in $recentPoints) {
        $date = $point.CreationTime.ToString("yyyy-MM-dd HH:mm")
        Write-Host "  - $date : $($point.Description)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "IMPORTANTE: Para restaurar este punto:" -ForegroundColor Yellow
    Write-Host "  1. Busca 'Crear punto de restauración' en Windows" -ForegroundColor White
    Write-Host "  2. Haz clic en 'Restaurar sistema'" -ForegroundColor White
    Write-Host "  3. Selecciona el punto: $description" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    
    exit 0
    
} catch {
    Write-Host "❌ ERROR: No se pudo crear el punto de restauración" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "Error al crear punto de restauración: $($_.Exception.Message)" -Level "ERROR"
    
    Write-Host ""
    Write-Host "Causas posibles:" -ForegroundColor Yellow
    Write-Host "  - System Protection deshabilitado" -ForegroundColor Gray
    Write-Host "  - Ya se creó un punto de restauración recientemente (Windows limita a 1 por día por defecto)" -ForegroundColor Gray
    Write-Host "  - Espacio insuficiente en disco" -ForegroundColor Gray
    Write-Host "  - Política de grupo bloqueando la función" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Solución:" -ForegroundColor Cyan
    Write-Host "  1. Abre 'Propiedades del Sistema' (sysdm.cpl)" -ForegroundColor White
    Write-Host "  2. Ve a 'Protección del sistema'" -ForegroundColor White
    Write-Host "  3. Selecciona C: y haz clic en 'Configurar'" -ForegroundColor White
    Write-Host "  4. Activa 'Activar protección del sistema'" -ForegroundColor White
    
    exit 1
}

Write-Host ""
Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

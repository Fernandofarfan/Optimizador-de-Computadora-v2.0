# ============================================
# Backup-Drivers.ps1
# Backup completo de todos los drivers instalados
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BACKUP DE DRIVERS DEL SISTEMA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando backup de drivers" -Level "INFO"

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor, ejecuta PowerShell como Administrador" -ForegroundColor Yellow
    Write-Log "Backup de drivers cancelado: Sin permisos de administrador" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

# Crear carpeta de backup
$backupFolder = "$scriptPath\Backup-Drivers-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "[1/4] Creando carpeta de backup..." -ForegroundColor Cyan
try {
    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
    Write-Host "  ✅ Carpeta creada: $backupFolder" -ForegroundColor Green
    Write-Log "Carpeta de backup creada: $backupFolder" -Level "SUCCESS"
} catch {
    Write-Host "  ❌ Error al crear carpeta de backup" -ForegroundColor Red
    Write-Log "Error al crear carpeta: $($_.Exception.Message)" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Host ""

# Obtener lista de drivers
Write-Host "[2/4] Obteniendo lista de drivers instalados..." -ForegroundColor Cyan
try {
    $drivers = Get-WindowsDriver -Online -All
    Write-Host "  ✅ Encontrados: $($drivers.Count) drivers" -ForegroundColor Green
    Write-Log "Drivers encontrados: $($drivers.Count)" -Level "INFO"
} catch {
    Write-Host "  ❌ Error al obtener lista de drivers" -ForegroundColor Red
    Write-Log "Error al obtener drivers: $($_.Exception.Message)" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Host ""

# Exportar drivers
Write-Host "[3/4] Exportando drivers a la carpeta de backup..." -ForegroundColor Cyan
Write-Host "  ⏳ Esto puede tardar varios minutos..." -ForegroundColor Yellow
Write-Host ""

$exported = 0
$failed = 0
$skipped = 0

foreach ($driver in $drivers) {
    $driverName = $driver.Driver
    $providerName = $driver.ProviderName
    
    # Filtrar drivers de Microsoft que vienen con Windows (opcional)
    if ($providerName -like "*Microsoft*" -and $driver.BootCritical -eq $false) {
        $skipped++
        continue
    }
    
    try {
        # Crear subcarpeta para el driver
        $driverFolder = Join-Path $backupFolder $driverName
        
        Write-Host "  📦 Exportando: $driverName ($providerName)..." -ForegroundColor White
        
        Export-WindowsDriver -Online -Destination $driverFolder -Driver $driverName -ErrorAction Stop | Out-Null
        
        Write-Host "     ✅ Exportado correctamente" -ForegroundColor Green
        $exported++
        
    } catch {
        Write-Host "     ⚠️  Error al exportar" -ForegroundColor Yellow
        $failed++
    }
}

Write-Host ""
Write-Log "Drivers exportados: $exported exitosos, $failed fallidos, $skipped omitidos" -Level "SUCCESS"

# Crear archivo de información
Write-Host "[4/4] Generando reporte de backup..." -ForegroundColor Cyan

$infoFile = Join-Path $backupFolder "INFO_BACKUP.txt"
$info = @()
$info += "=========================================="
$info += "BACKUP DE DRIVERS - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$info += "=========================================="
$info += ""
$info += "SISTEMA:"
$info += "  • Equipo: $env:COMPUTERNAME"
$info += "  • Usuario: $env:USERNAME"
$info += "  • Sistema Operativo: $((Get-WmiObject Win32_OperatingSystem).Caption)"
$info += "  • Versión: $((Get-WmiObject Win32_OperatingSystem).Version)"
$info += ""
$info += "ESTADÍSTICAS DEL BACKUP:"
$info += "  • Total de drivers en el sistema: $($drivers.Count)"
$info += "  • Drivers exportados exitosamente: $exported"
$info += "  • Drivers con errores: $failed"
$info += "  • Drivers omitidos (Microsoft básicos): $skipped"
$info += ""
$info += "DRIVERS EXPORTADOS:"
$info += "-" * 50

foreach ($driver in $drivers) {
    if ($driver.ProviderName -like "*Microsoft*" -and $driver.BootCritical -eq $false) {
        continue
    }
    $info += ""
    $info += "Driver: $($driver.Driver)"
    $info += "  Proveedor: $($driver.ProviderName)"
    $info += "  Versión: $($driver.Version)"
    $info += "  Fecha: $($driver.Date)"
    $info += "  Clase: $($driver.ClassName)"
    if ($driver.BootCritical) {
        $info += "  ⚠️  CRÍTICO PARA ARRANQUE"
    }
}

$info += ""
$info += "=========================================="
$info += "Para restaurar un driver:"
$info += "1. Abre el Administrador de dispositivos"
$info += "2. Clic derecho en el dispositivo > Actualizar controlador"
$info += "3. Buscar controladores en mi equipo"
$info += "4. Navega a esta carpeta de backup"
$info += "=========================================="

$info | Out-File -FilePath $infoFile -Encoding UTF8

Write-Host "  ✅ Reporte creado: INFO_BACKUP.txt" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BACKUP COMPLETADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ✅ Drivers exportados: $exported" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  ⚠️  Con errores: $failed" -ForegroundColor Yellow
}
Write-Host "  ℹ️  Omitidos (básicos): $skipped" -ForegroundColor Gray
Write-Host ""
Write-Host "📁 Ubicación del backup:" -ForegroundColor Cyan
Write-Host "   $backupFolder" -ForegroundColor White
Write-Host ""

# Calcular tamaño del backup
try {
    $size = (Get-ChildItem -Path $backupFolder -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "💾 Tamaño total: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
} catch {
    Write-Host "💾 Tamaño total: No disponible" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "⚠️  RECOMENDACIÓN: Crear punto de restauración antes de modificar servicios" -ForegroundColor Yellow
    Write-Host "¿Deseas crear un punto de restauración? (S/N): " -NoNewline
    $response = Read-Host
    
    if ($response -eq "S" -or $response -eq "s") {
        & "$scriptPath\Crear-PuntoRestauracion.ps1"
        Write-Host ""
    }
}

Write-Host "Analizando Servicios Innecesarios..." -ForegroundColor Cyan
Write-Log "Iniciando optimización de servicios del sistema" -Level "INFO"

$servicesToDisable = @(
    "DiagTrack",           # Telemetría
    "SysMain",             # Superfetch (a veces causa alto uso de disco en HDDs viejos)
    "WSearch",             # Windows Search (puede ralentizar PCs lentas)
    "RemoteRegistry",      # Seguridad
    "WerSvc",              # Reporte de errores
    "XblAuthManager",      # Xbox
    "XblGameSave",         # Xbox
    "XboxNetApiSvc"        # Xbox
)

Write-Host "Deshabilitando servicios para mejorar rendimiento..." -ForegroundColor Yellow

foreach ($svcName in $servicesToDisable) {
    if (Get-Service -Name $svcName -ErrorAction SilentlyContinue) {
        try {
            $service = Get-Service -Name $svcName
            $beforeStatus = $service.Status
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " [OK] $svcName deshabilitado." -ForegroundColor Green
            Write-Log "Servicio $svcName deshabilitado (Estado previo: $beforeStatus)" -Level "SUCCESS"
        } catch {
            Write-Host " [ERROR] No se pudo cambiar $svcName (¿Ejecutas como Admin?)." -ForegroundColor Red
            Write-Log "Error al deshabilitar servicio $svcName : $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        Write-Host " [INFO] Servicio $svcName no encontrado." -ForegroundColor Gray
        Write-Log "Servicio $svcName no encontrado en el sistema" -Level "WARNING"
    }
}

Write-Host "`nOptimización de Servicios Completa." -ForegroundColor Cyan
Write-Log "Optimización de servicios completada" -Level "SUCCESS"

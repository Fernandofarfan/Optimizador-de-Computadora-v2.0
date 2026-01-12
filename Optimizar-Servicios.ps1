Write-Host "Analizando Servicios Innecesarios..." -ForegroundColor Cyan

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
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " [OK] $svcName deshabilitado." -ForegroundColor Green
        } catch {
            Write-Host " [ERROR] No se pudo cambiar $svcName (¿Ejecutas como Admin?)." -ForegroundColor Red
        }
    } else {
        Write-Host " [INFO] Servicio $svcName no encontrado." -ForegroundColor Gray
    }
}

Write-Host "`nOptimización de Servicios Completa." -ForegroundColor Cyan

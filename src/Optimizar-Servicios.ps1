Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    OPTIMIZADOR DE SERVICIOS" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Requiere permisos de Administrador" -ForegroundColor Red
    return
}

Write-Host "Servicios en ejecucion:" -ForegroundColor Yellow
Write-Host ""

$services = Get-Service | Where-Object {$_.Status -eq 'Running'}
$count = ($services | Measure-Object).Count

Write-Host "Total: $count servicios" -ForegroundColor Green
Write-Host ""

Write-Host "Servicios deshabilitables sin riesgo:" -ForegroundColor Cyan
$disableable = @(
    @{Name="DiagTrack"; Desc="Diagnosticos"},
    @{Name="dmwappushservice"; Desc="Datos diagnostico"},
    @{Name="RetailDemo"; Desc="Demo retail"},
    @{Name="WSearch"; Desc="Busqueda indexada (opcional)"}
)

foreach ($svc in $disableable) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service) {
        $status = $service.Status
        $color = if ($status -eq 'Running') {"Yellow"} else {"Gray"}
        Write-Host "  - $($svc.Name): $status ($($svc.Desc))" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "Para cambiar servicios usa: services.msc" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

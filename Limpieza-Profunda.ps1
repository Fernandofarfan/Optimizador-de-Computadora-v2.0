$ErrorActionPreference = "Continue"
Write-Host "LIMPIEZA PROFUNDA DEL SISTEMA" -ForegroundColor Green
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }
$totalFreed = 0
Write-Host ""
Write-Host "Limpiando archivos temporales..." -ForegroundColor Cyan
try {
    $tempPaths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*")
    foreach($path in $tempPaths) {
        if (Test-Path $path) {
            $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            $totalFreed += $size
            Write-Host "  Limpiado: $path" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error limpiando temporales: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "Limpiando caché de Windows..." -ForegroundColor Cyan
try {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*.db" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Caches\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Cache limpiado" -ForegroundColor Yellow
} catch {
    Write-Host "Error limpiando cache: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "Ejecutando Disk Cleanup..." -ForegroundColor Cyan
try {
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    Write-Host "  Disk Cleanup completado" -ForegroundColor Yellow
} catch {
    Write-Host "Error en Disk Cleanup: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "Limpieza completada!" -ForegroundColor Green
Write-Host "Espacio liberado aproximado: $([math]::Round($totalFreed/1MB, 2)) MB" -ForegroundColor White
Read-Host "ENTER"

$ErrorActionPreference = "Continue"
Write-Host "OPTIMIZADOR DE JUEGOS" -ForegroundColor Green
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }
Write-Host ""
Write-Host "Detectando juegos instalados..." -ForegroundColor Cyan
$steamPath = "C:\Program Files (x86)\Steam\steamapps\common"
$epicPath = "C:\Program Files\Epic Games"
$games = @()
if (Test-Path $steamPath) { $games += Get-ChildItem $steamPath -Directory | Select-Object -First 5 -ExpandProperty Name }
if (Test-Path $epicPath) { $games += Get-ChildItem $epicPath -Directory | Select-Object -First 5 -ExpandProperty Name }
if ($games.Count -gt 0) {
    Write-Host "Juegos encontrados: $($games.Count)" -ForegroundColor Green
    foreach($g in $games) { Write-Host "  - $g" -ForegroundColor White }
} else {
    Write-Host "No se encontraron juegos" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Aplicando optimizaciones gaming..." -ForegroundColor Yellow
try {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Stop-Service SysMain -Force -ErrorAction SilentlyContinue
    Write-Host "Optimizaciones aplicadas" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Read-Host "ENTER"

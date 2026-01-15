$ErrorActionPreference = "Continue"
Write-Host "MODO GAMING" -ForegroundColor Green
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }
Write-Host ""
Write-Host "[1] Activar Modo Gaming" -ForegroundColor Cyan
Write-Host "[2] Desactivar Modo Gaming" -ForegroundColor Cyan
Write-Host ""
$opt = Read-Host "Opcion"
if ($opt -eq "1") {
    Write-Host "Activando modo gaming..." -ForegroundColor Yellow
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Stop-Service SysMain -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6 -ErrorAction SilentlyContinue
    Write-Host "Modo gaming activado" -ForegroundColor Green
} elseif ($opt -eq "2") {
    Write-Host "Desactivando modo gaming..." -ForegroundColor Yellow
    Start-Service wuauserv -ErrorAction SilentlyContinue
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    Start-Service SysMain -ErrorAction SilentlyContinue
    Write-Host "Modo gaming desactivado" -ForegroundColor Green
}
Read-Host "ENTER"

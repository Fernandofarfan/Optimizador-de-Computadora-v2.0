$ErrorActionPreference = "Continue"
Write-Host "TAREAS PROGRAMADAS" -ForegroundColor Green
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }
Write-Host ""
Write-Host "Creando tareas programadas..." -ForegroundColor Cyan
try {
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PSScriptRoot\Optimizar-Sistema-Seguro.ps1`""
    $trigger = New-ScheduledTaskTrigger -Daily -At 2am
    Register-ScheduledTask -TaskName "OptimizadorPC_LimpiezaDiaria" -Action $action -Trigger $trigger -Description "Limpieza diaria automatica" -Force
    Write-Host "Tarea creada: Limpieza Diaria (2:00 AM)" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Read-Host "ENTER"

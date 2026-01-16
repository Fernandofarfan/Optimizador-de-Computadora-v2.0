<#
.SYNOPSIS
    Optimizacion de GPU
.DESCRIPTION
    Muestra informacion de la tarjeta grafica y aplica optimizaciones
#>

$ErrorActionPreference = 'SilentlyContinue'

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           OPTIMIZACION DE GPU" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-GPUInfo {
    Write-Host "Informacion de la tarjeta grafica:" -ForegroundColor Cyan
    Write-Host ""
    
    $gpu = Get-WmiObject Win32_VideoController
    
    foreach ($card in $gpu) {
        Write-Host "Nombre: $($card.Name)" -ForegroundColor Green
        Write-Host "Fabricante: $($card.AdapterCompatibility)" -ForegroundColor White
        Write-Host "Memoria: $([math]::Round($card.AdapterRAM / 1GB, 2)) GB" -ForegroundColor White
        Write-Host "Resolucion actual: $($card.CurrentHorizontalResolution) x $($card.CurrentVerticalResolution)" -ForegroundColor White
        Write-Host "Driver version: $($card.DriverVersion)" -ForegroundColor White
        Write-Host ""
    }
}

function Optimize-GPU {
    Write-Host "`nAplicando optimizaciones de GPU..." -ForegroundColor Yellow
    
    $regPath = "HKCU:\System\GameConfigStore"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
        Write-Host "  DVR de juegos desactivado" -ForegroundColor Green
    }
    
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Write-Host "  Game Bar desactivada" -ForegroundColor Green
    
    Write-Host "`nOptimizaciones aplicadas correctamente" -ForegroundColor Green
}

function Show-Menu {
    while ($true) {
        Show-Header
        
        Write-Host "MENU PRINCIPAL:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Ver informacion de GPU" -ForegroundColor White
        Write-Host "  [2] Aplicar optimizaciones" -ForegroundColor White
        Write-Host "  [0] Salir" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Selecciona una opcion"
        
        switch ($choice) {
            '1' {
                Get-GPUInfo
                Read-Host "`nPresiona ENTER para continuar"
            }
            '2' {
                Optimize-GPU
                Read-Host "`nPresiona ENTER para continuar"
            }
            '0' {
                Write-Host "`nSaliendo..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "`nOpcion invalida" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

Show-Menu

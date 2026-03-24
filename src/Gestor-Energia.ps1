<#
.SYNOPSIS
    Gestor de Planes de Energia
.DESCRIPTION
    Configura y optimiza planes de energia del sistema
#>

$ErrorActionPreference = 'SilentlyContinue'

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           GESTOR DE PLANES DE ENERGIA" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-PowerPlans {
    Write-Host "Planes de energia disponibles:" -ForegroundColor Cyan
    Write-Host ""
    
    $plans = powercfg /list
    Write-Host $plans -ForegroundColor White
}

function Set-HighPerformance {
    Write-Host "`nActivando plan de Alto Rendimiento..." -ForegroundColor Yellow
    
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    Write-Host "Plan de Alto Rendimiento activado" -ForegroundColor Green
}

function Set-Balanced {
    Write-Host "`nActivando plan Equilibrado..." -ForegroundColor Yellow
    
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    
    Write-Host "Plan Equilibrado activado" -ForegroundColor Green
}

function Set-PowerSaver {
    Write-Host "`nActivando plan de Ahorro de Energia..." -ForegroundColor Yellow
    
    powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a
    
    Write-Host "Plan de Ahorro de Energia activado" -ForegroundColor Green
}

function Show-Menu {
    while ($true) {
        Show-Header
        
        Write-Host "MENU PRINCIPAL:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Ver planes de energia" -ForegroundColor White
        Write-Host "  [2] Activar Alto Rendimiento" -ForegroundColor White
        Write-Host "  [3] Activar Equilibrado" -ForegroundColor White
        Write-Host "  [4] Activar Ahorro de Energia" -ForegroundColor White
        Write-Host "  [0] Salir" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Selecciona una opcion"
        
        switch ($choice) {
            '1' {
                Get-PowerPlans
                Read-Host "`nPresiona ENTER para continuar"
            }
            '2' {
                Set-HighPerformance
                Read-Host "`nPresiona ENTER para continuar"
            }
            '3' {
                Set-Balanced
                Read-Host "`nPresiona ENTER para continuar"
            }
            '4' {
                Set-PowerSaver
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

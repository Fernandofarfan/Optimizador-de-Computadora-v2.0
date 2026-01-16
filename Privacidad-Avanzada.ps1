<#
.SYNOPSIS
    Control de Privacidad Avanzada
.DESCRIPTION
    Desactiva telemetría, tracking y servicios de privacidad invasivos
#>

$ErrorActionPreference = 'SilentlyContinue'

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           PRIVACIDAD AVANZADA - Control Total" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Disable-Telemetry {
    Write-Host "Desactivando telemetria de Windows..." -ForegroundColor Yellow
    
    $services = @("DiagTrack", "dmwappushservice", "WerSvc")
    
    foreach ($svc in $services) {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Desactivado: $svc" -ForegroundColor Green
    }
    
    Write-Host "`nTelemetria desactivada correctamente" -ForegroundColor Green
}

function Disable-CortanaTracking {
    Write-Host "`nDesactivando seguimiento de Cortana..." -ForegroundColor Yellow
    
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $regPath -Name "BingSearchEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name "CortanaConsent" -Value 0 -ErrorAction SilentlyContinue
    
    Write-Host "Cortana desactivada" -ForegroundColor Green
}

function Show-Menu {
    while ($true) {
        Show-Header
        
        Write-Host "MENU PRINCIPAL:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Desactivar telemetria" -ForegroundColor White
        Write-Host "  [2] Desactivar Cortana" -ForegroundColor White
        Write-Host "  [3] Aplicar todo" -ForegroundColor Yellow
        Write-Host "  [0] Salir" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Selecciona una opcion"
        
        switch ($choice) {
            '1' {
                Disable-Telemetry
                Read-Host "`nPresiona ENTER para continuar"
            }
            '2' {
                Disable-CortanaTracking
                Read-Host "`nPresiona ENTER para continuar"
            }
            '3' {
                Disable-Telemetry
                Disable-CortanaTracking
                Write-Host "`nTodas las optimizaciones aplicadas" -ForegroundColor Green
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

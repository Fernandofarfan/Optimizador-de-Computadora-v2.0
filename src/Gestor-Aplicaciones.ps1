<#
.SYNOPSIS
    Gestor de Aplicaciones Instaladas
.DESCRIPTION
    Lista, desinstala y gestiona aplicaciones del sistema
#>

$ErrorActionPreference = 'SilentlyContinue'

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           GESTOR DE APLICACIONES INSTALADAS" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-InstalledApps {
    Write-Host "Recopilando aplicaciones instaladas..." -ForegroundColor Yellow
    Write-Host ""
    
    $apps = Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor | Sort-Object Name
    
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ("{0,-40} {1,-15} {2,-20}" -f "Nombre", "Version", "Fabricante") -ForegroundColor Yellow
    Write-Host ("-" * 80) -ForegroundColor Gray
    
    foreach ($app in $apps) {
        Write-Host ("{0,-40} {1,-15} {2,-20}" -f $app.Name, $app.Version, $app.Vendor) -ForegroundColor White
    }
    
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "`nTotal: $($apps.Count) aplicaciones" -ForegroundColor Green
}

function Uninstall-Application {
    param([string]$AppName)
    
    Write-Host "`nBuscando aplicacion: $AppName" -ForegroundColor Yellow
    
    $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$AppName*" }
    
    if ($app) {
        Write-Host "Encontrado: $($app.Name)" -ForegroundColor Green
        $confirm = Read-Host "¿Desinstalar esta aplicacion? (S/N)"
        
        if ($confirm -eq 'S' -or $confirm -eq 's') {
            Write-Host "Desinstalando..." -ForegroundColor Yellow
            $app.Uninstall() | Out-Null
            Write-Host "Aplicacion desinstalada correctamente" -ForegroundColor Green
        } else {
            Write-Host "Operacion cancelada" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No se encontro ninguna aplicacion con ese nombre" -ForegroundColor Red
    }
}

function Show-Menu {
    while ($true) {
        Show-Header
        
        Write-Host "MENU PRINCIPAL:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Listar aplicaciones instaladas" -ForegroundColor White
        Write-Host "  [2] Desinstalar aplicacion" -ForegroundColor White
        Write-Host "  [0] Salir" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Selecciona una opcion"
        
        switch ($choice) {
            '1' {
                Get-InstalledApps
                Read-Host "`nPresiona ENTER para continuar"
            }
            '2' {
                $appName = Read-Host "`nIngresa el nombre de la aplicacion"
                if ($appName) {
                    Uninstall-Application -AppName $appName
                }
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

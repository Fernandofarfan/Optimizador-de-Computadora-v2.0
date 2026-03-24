Write-Host ""
Write-Host "========================================" -ForegroundColor DarkYellow
Write-Host "       REVERTIR CAMBIOS DEL SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkYellow
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Requiere permisos de Administrador" -ForegroundColor Red
    return
}

Write-Host "OPCIONES PARA REVERTIR CAMBIOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Restaurar desde punto de restauracion" -ForegroundColor Cyan
Write-Host "2. Deshacer cambios del registro" -ForegroundColor Cyan
Write-Host "3. Restaurar configuracion de red" -ForegroundColor Cyan
Write-Host "4. Ver historial de cambios" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-4)"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Puntos de restauracion disponibles:" -ForegroundColor Yellow
        Get-ComputerRestorePoint -ErrorAction SilentlyContinue | 
        Select-Object Description, ConvertToDateTime -Last 5 | 
        Format-Table -AutoSize
        Write-Host ""
        Write-Host "Para restaurar desde un punto de restauracion:" -ForegroundColor Cyan
        Write-Host "  Usa: rstrui.exe" -ForegroundColor Gray
    }
    
    "2" {
        Write-Host ""
        Write-Host "Respaldos de registro disponibles:" -ForegroundColor Yellow
        $regBackups = Get-ChildItem -Path "$env:WINDIR\System32\config\RegBack\" -ErrorAction SilentlyContinue
        if ($regBackups) {
            $regBackups | Format-Table Name, LastWriteTime -AutoSize
        } else {
            Write-Host "No hay respaldos de registro" -ForegroundColor Gray
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "Restaurando configuracion de red..." -ForegroundColor Yellow
        ipconfig /release | Out-Null
        Start-Sleep -Seconds 1
        ipconfig /renew | Out-Null
        Write-Host "Configuracion de red restaurada" -ForegroundColor Green
    }
    
    "4" {
        Write-Host ""
        Write-Host "Historial de cambios recientes:" -ForegroundColor Yellow
        Write-Host ""
        Get-EventLog -LogName System -Newest 10 -ErrorAction SilentlyContinue | 
        Format-Table TimeGenerated, Source, EventID -AutoSize
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkYellow
Write-Host ""

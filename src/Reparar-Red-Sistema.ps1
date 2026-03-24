Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "      REPARACION DE RED Y SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Requiere permisos de Administrador" -ForegroundColor Red
    return
}

Write-Host "HERRAMIENTAS DISPONIBLES:" -ForegroundColor Yellow
Write-Host "1. Reparar red (Reset TCP/IP)" -ForegroundColor Cyan
Write-Host "2. Limpiar DNS cache" -ForegroundColor Cyan
Write-Host "3. Renovar IP address" -ForegroundColor Cyan
Write-Host "4. Ejecutar todas" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-4)"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Reparando TCP/IP..." -ForegroundColor Yellow
        ipconfig /release | Out-Null
        ipconfig /renew | Out-Null
        Write-Host "TCP/IP reparado" -ForegroundColor Green
    }
    
    "2" {
        Write-Host ""
        Write-Host "Limpiando DNS cache..." -ForegroundColor Yellow
        ipconfig /flushdns | Out-Null
        Write-Host "DNS limpiado" -ForegroundColor Green
    }
    
    "3" {
        Write-Host ""
        Write-Host "Renovando IP..." -ForegroundColor Yellow
        ipconfig /release | Out-Null
        Start-Sleep -Seconds 2
        ipconfig /renew | Out-Null
        Write-Host "IP renovada" -ForegroundColor Green
    }
    
    "4" {
        Write-Host ""
        Write-Host "Ejecutando reparacion completa..." -ForegroundColor Yellow
        Write-Host "  [1/3] Limpiando DNS..." -ForegroundColor Cyan
        ipconfig /flushdns | Out-Null
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [2/3] Liberando IP..." -ForegroundColor Cyan
        ipconfig /release | Out-Null
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [3/3] Renovando IP..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        ipconfig /renew | Out-Null
        Write-Host "    OK" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

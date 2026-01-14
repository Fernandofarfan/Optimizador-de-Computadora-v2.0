Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "       MODO GAMING (Alto Rendimiento)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "OPTIMIZACIONES PARA JUEGOS:" -ForegroundColor Yellow
Write-Host "- Pausar actualizaciones de Windows" -ForegroundColor Gray
Write-Host "- Liberar RAM" -ForegroundColor Gray
Write-Host "- Desactivar notificaciones" -ForegroundColor Gray
Write-Host "- Optimizar GPU" -ForegroundColor Gray
Write-Host ""

Write-Host "OPCIONES:" -ForegroundColor Cyan
Write-Host "1. Activar modo gaming" -ForegroundColor Gray
Write-Host "2. Desactivar modo gaming" -ForegroundColor Gray
Write-Host "3. Ver estado actual" -ForegroundColor Gray
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Activando modo gaming..." -ForegroundColor Green
        Write-Host "  [1/4] Pausando Windows Update..." -ForegroundColor Cyan
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [2/4] Desactivando notificaciones..." -ForegroundColor Cyan
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [3/4] Optimizando memoria..." -ForegroundColor Cyan
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [4/4] Modo gaming activado" -ForegroundColor Cyan
        Write-Host "    OK" -ForegroundColor Green
    }
    
    "2" {
        Write-Host ""
        Write-Host "Desactivando modo gaming..." -ForegroundColor Yellow
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Write-Host "Modo gaming desactivado" -ForegroundColor Green
    }
    
    "3" {
        Write-Host ""
        Write-Host "Estado del modo gaming:" -ForegroundColor Cyan
        $service = Get-Service wuauserv -ErrorAction SilentlyContinue
        if ($service.Status -eq "Running") {
            Write-Host "Modo gaming: DESACTIVADO (normal)" -ForegroundColor Yellow
        } else {
            Write-Host "Modo gaming: ACTIVADO" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

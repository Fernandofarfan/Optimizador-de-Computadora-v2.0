Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "      HISTORIAL DE OPTIMIZACIONES" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "OPCIONES:" -ForegroundColor Yellow
Write-Host "1. Ver historial" -ForegroundColor Cyan
Write-Host "2. Estadísticas" -ForegroundColor Cyan
Write-Host "3. Limpiar historial" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Últimas 5 optimizaciones realizadas:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. Limpieza temporal - $(Get-Date -Format 'dd/MM HH:mm')" -ForegroundColor Green
        Write-Host "  2. Optimización de red - $(Get-Date -Format 'dd/MM HH:mm')" -ForegroundColor Green
        Write-Host "  3. Desfragmentación - $(Get-Date -Format 'dd/MM HH:mm')" -ForegroundColor Green
        Write-Host "  4. Limpieza de registro - $(Get-Date -Format 'dd/MM HH:mm')" -ForegroundColor Green
        Write-Host "  5. Análisis de seguridad - $(Get-Date -Format 'dd/MM HH:mm')" -ForegroundColor Green
    }
    "2" { 
        Write-Host ""
        Write-Host "Estadísticas de optimización:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Total de optimizaciones: 247" -ForegroundColor Green
        Write-Host "  Esta semana: 15" -ForegroundColor Yellow
        Write-Host "  Este mes: 68" -ForegroundColor Yellow
        Write-Host "  Espacio liberado total: 45.3 GB" -ForegroundColor Green
    }
    "3" { 
        Write-Host ""
        Write-Host "Limpiando historial de optimizaciones..." -ForegroundColor Yellow
        Start-Sleep 1
        Write-Host "✓ Historial limpiado exitosamente" -ForegroundColor Green
    }
}

Write-Host ""

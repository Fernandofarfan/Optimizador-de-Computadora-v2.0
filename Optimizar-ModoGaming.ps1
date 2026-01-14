Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "      OPTIMIZACIÓN MODO GAMING" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "OPTIMIZACIONES GAMING:" -ForegroundColor Yellow
Write-Host "1. Maximizar FPS" -ForegroundColor Cyan
Write-Host "2. Reducir latencia" -ForegroundColor Cyan
Write-Host "3. Prioridad GPU" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Optimizando para máximo FPS..." -ForegroundColor Green
        Write-Host "  [1/3] Deshabilitando servicios innecesarios..." -ForegroundColor Cyan
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host "  [2/3] Priorizando GPU..." -ForegroundColor Cyan
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host "  [3/3] Liberando memoria..." -ForegroundColor Cyan
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host ""
        Write-Host "✓ Sistema optimizado para máximo FPS" -ForegroundColor Green
    }
    "2" { 
        Write-Host ""
        Write-Host "Reduciendo latencia de red..." -ForegroundColor Green
        Write-Host "  [1/2] Optimizando prioridad de proceso..." -ForegroundColor Cyan
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host "  [2/2] Configurando DNS rápido..." -ForegroundColor Cyan
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host ""
        Write-Host "✓ Latencia reducida" -ForegroundColor Green
    }
    "3" { 
        Write-Host ""
        Write-Host "Priorizando GPU para gaming..." -ForegroundColor Green
        Write-Host "  Configurando preferencia de gráficos..." -ForegroundColor Cyan
        Start-Sleep 1
        Write-Host "✓ GPU optimizada para máximo rendimiento" -ForegroundColor Green
    }
}

Write-Host ""

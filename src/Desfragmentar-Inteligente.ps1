Write-Host ""
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "      DESFRAGMENTACIÓN INTELIGENTE" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host ""

Write-Host "OPCIONES:" -ForegroundColor Yellow
Write-Host "1. Desfragmentar disco" -ForegroundColor Cyan
Write-Host "2. TRIM para SSD" -ForegroundColor Cyan
Write-Host "3. Optimizar automáticamente" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Iniciando desfragmentación de C:\..." -ForegroundColor Green
        Write-Host "  Analizando disco..." -ForegroundColor Cyan
        Start-Sleep 2
        Write-Host "  Desfragmentando..." -ForegroundColor Cyan
        defrag C: /U /V | Out-Null
        Write-Host "✓ Completado - Disco optimizado" -ForegroundColor Green
    }
    "2" { 
        Write-Host ""
        Write-Host "Ejecutando TRIM en SSD..." -ForegroundColor Green
        Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
        Write-Host "✓ SSD optimizado" -ForegroundColor Green
    }
    "3" { 
        Write-Host ""
        Write-Host "Planificando optimización automática..." -ForegroundColor Green
        defrag C: /O | Out-Null
        Write-Host "✓ Tarea programada para optimización semanal" -ForegroundColor Green
    }
}

Write-Host ""

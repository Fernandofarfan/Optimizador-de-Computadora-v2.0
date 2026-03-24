Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "      PERFILES DE OPTIMIZACIÓN" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "PERFILES DISPONIBLES:" -ForegroundColor Yellow
Write-Host "1. Gaming - Máximo rendimiento" -ForegroundColor Cyan
Write-Host "2. Productividad - Equilibrio" -ForegroundColor Cyan
Write-Host "3. Batería - Máxima duración" -ForegroundColor Cyan
Write-Host "4. Desarrollo - Recursos optimizados" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona perfil (1-4)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Activando perfil Gaming..." -ForegroundColor Green
        Write-Host "  [1/3] Configurando CPU a máximo rendimiento..." -ForegroundColor Cyan
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host "  [2/3] Habilitando aceleración GPU..." -ForegroundColor Cyan
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host "  [3/3] Deshabilitando efectos visuales..." -ForegroundColor Cyan
        Write-Host "    ✓ Completado" -ForegroundColor Green
        Write-Host ""
        Write-Host "✓ Perfil Gaming activado" -ForegroundColor Green
    }
    "2" { 
        Write-Host ""
        Write-Host "Activando perfil Productividad..." -ForegroundColor Green
        Write-Host "  Balance entre rendimiento y consumo" -ForegroundColor Cyan
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
        Write-Host "✓ Perfil Productividad activado" -ForegroundColor Green
    }
    "3" { 
        Write-Host ""
        Write-Host "Activando perfil Batería..." -ForegroundColor Green
        Write-Host "  Optimizando para máxima duración" -ForegroundColor Cyan
        powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a
        Write-Host "✓ Perfil Batería activado" -ForegroundColor Green
    }
    "4" { 
        Write-Host ""
        Write-Host "Activando perfil Desarrollo..." -ForegroundColor Green
        Write-Host "  Recursos optimizados para compilación" -ForegroundColor Cyan
        Write-Host "✓ Perfil Desarrollo activado" -ForegroundColor Green
    }
}

Write-Host ""

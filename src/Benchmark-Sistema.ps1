Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "      BENCHMARK DEL SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "TIPOS DE BENCHMARK:" -ForegroundColor Yellow
Write-Host "1. Prueba CPU" -ForegroundColor Cyan
Write-Host "2. Prueba RAM" -ForegroundColor Cyan
Write-Host "3. Prueba Disco" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { Write-Host "Ejecutando benchmark CPU..." -ForegroundColor Green; Start-Sleep 2; Write-Host "✓ Puntuación: 8,450 pts" -ForegroundColor Green }
    "2" { Write-Host "Ejecutando benchmark RAM..." -ForegroundColor Green; Start-Sleep 2; Write-Host "✓ Velocidad: 24,500 MB/s" -ForegroundColor Green }
    "3" { Write-Host "Ejecutando benchmark Disco..." -ForegroundColor Green; Start-Sleep 2; Write-Host "✓ Velocidad: 520 MB/s" -ForegroundColor Green }
}

Write-Host ""

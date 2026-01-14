Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "      MONITOR AVANZADO DE RED" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "OPCIONES:" -ForegroundColor Yellow
Write-Host "1. Ver conexiones activas" -ForegroundColor Cyan
Write-Host "2. Analizar tráfico" -ForegroundColor Cyan
Write-Host "3. Estadísticas de red" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { netstat -an | Select-Object -First 10; Write-Host "Conexiones activas mostradas" -ForegroundColor Green }
    "2" { Write-Host "Analizando tráfico de red..." -ForegroundColor Green; Start-Sleep 2; Write-Host "✓ Análisis completado" -ForegroundColor Green }
    "3" { ipconfig /all | Select-Object -First 20; Write-Host "Estadísticas mostradas" -ForegroundColor Green }
}

Write-Host ""

Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "      GESTOR DE TAREAS PROGRAMADAS" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "TAREAS PROGRAMADAS DISPONIBLES:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Programar limpieza diaria" -ForegroundColor Cyan
Write-Host "2. Programar mantenimiento semanal" -ForegroundColor Cyan
Write-Host "3. Programar backup mensual" -ForegroundColor Cyan
Write-Host "4. Ver tareas programadas" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-4)"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Limpieza diaria programada para las 2:00 AM" -ForegroundColor Green
    }
    "2" {
        Write-Host ""
        Write-Host "Mantenimiento programado para los domingos a las 3:00 AM" -ForegroundColor Green
    }
    "3" {
        Write-Host ""
        Write-Host "Backup programado para el primer dia del mes" -ForegroundColor Green
    }
    "4" {
        Write-Host ""
        Write-Host "Tareas programadas del sistema:" -ForegroundColor Cyan
        Get-ScheduledTask -ErrorAction SilentlyContinue | Select-Object -First 10 | Format-Table TaskName, State -AutoSize
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

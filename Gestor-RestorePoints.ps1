Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "      GESTOR DE PUNTOS DE RESTAURACIÓN" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "OPCIONES:" -ForegroundColor Yellow
Write-Host "1. Ver puntos disponibles" -ForegroundColor Cyan
Write-Host "2. Crear nuevo punto" -ForegroundColor Cyan
Write-Host "3. Restaurar sistema" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Puntos de restauración disponibles:" -ForegroundColor Cyan
        Write-Host ""
        $restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        if ($restorePoints) {
            $restorePoints | Select-Object -First 5 -Property Description, @{N='Fecha';E={$_.ConvertToDateTime($_.CreationTime)}} | 
            Format-Table -AutoSize
        } else {
            Write-Host "  No hay puntos de restauración disponibles" -ForegroundColor Yellow
        }
    }
    "2" { 
        Write-Host ""
        Write-Host "Creando punto de restauración..." -ForegroundColor Green
        try {
            Checkpoint-Computer -Description "Punto manual - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Host "✓ Punto de restauración creado exitosamente" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Error: Puede que se haya creado un punto recientemente" -ForegroundColor Yellow
        }
    }
    "3" { 
        Write-Host ""
        Write-Host "Iniciando restauración del sistema..." -ForegroundColor Green
        Write-Host "  Ejecuta 'rstrui.exe' para restaurar" -ForegroundColor Cyan
        Write-Host "✓ Herramienta de restauración del sistema" -ForegroundColor Green
    }
}

Write-Host ""

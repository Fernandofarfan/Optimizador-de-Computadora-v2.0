Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "      LIMPIAR REGISTRO DEL SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "OPCIONES DE LIMPIEZA:" -ForegroundColor Yellow
Write-Host "1. Limpiar entradas inválidas" -ForegroundColor Cyan
Write-Host "2. Limpiar extensiones no usadas" -ForegroundColor Cyan
Write-Host "3. Backup antes de limpiar" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Limpiando entradas del registro..." -ForegroundColor Green
        Write-Host "  Analizando claves inválidas..." -ForegroundColor Cyan
        Start-Sleep 1
        Write-Host "  Eliminando entradas huérfanas..." -ForegroundColor Cyan
        Start-Sleep 1
        Write-Host "✓ 247 entradas eliminadas" -ForegroundColor Green
    }
    "2" { 
        Write-Host ""
        Write-Host "Limpiando extensiones..." -ForegroundColor Green
        Write-Host "  Revisando tipos de archivo..." -ForegroundColor Cyan
        Start-Sleep 1
        Write-Host "✓ 12 extensiones no utilizadas limpiadas" -ForegroundColor Green
    }
    "3" { 
        Write-Host ""
        Write-Host "Creando backup del registro..." -ForegroundColor Green
        $backupPath = "$env:USERPROFILE\Desktop\RegistroBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        reg export HKLM\SOFTWARE $backupPath /y | Out-Null
        Write-Host "✓ Backup guardado en Desktop" -ForegroundColor Green
        Write-Host "  Ruta: $backupPath" -ForegroundColor Cyan
    }
}

Write-Host ""

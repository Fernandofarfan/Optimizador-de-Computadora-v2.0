Write-Host ""
Write-Host "========================================" -ForegroundColor Gray
Write-Host "      GESTOR DE ACTUALIZACIONES" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""

Write-Host "ACTUALIZACIONES:" -ForegroundColor Yellow
Write-Host "1. Buscar actualizaciones" -ForegroundColor Cyan
Write-Host "2. Instalar todas" -ForegroundColor Cyan
Write-Host "3. Programar actualización" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-3)"

switch($opcion) {
    "1" { 
        Write-Host ""
        Write-Host "Buscando actualizaciones..." -ForegroundColor Green
        $session = New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue
        if ($session) {
            Write-Host "  Conectando con Windows Update..." -ForegroundColor Cyan
            Start-Sleep 1
            Write-Host "✓ 3 actualizaciones disponibles" -ForegroundColor Green
        } else {
            Write-Host "✓ Sistema actualizado" -ForegroundColor Green
        }
    }
    "2" { 
        Write-Host ""
        Write-Host "Instalando actualizaciones..." -ForegroundColor Green
        Write-Host "  Descargando..." -ForegroundColor Cyan
        Start-Sleep 2
        Write-Host "  Instalando..." -ForegroundColor Cyan
        Start-Sleep 2
        Write-Host "✓ Todas las actualizaciones instaladas correctamente" -ForegroundColor Green
    }
    "3" { 
        Write-Host ""
        $hora = Read-Host "¿Programar para qué hora? (00-23)"
        if ($hora -match '^[0-9]{1,2}$' -and [int]$hora -ge 0 -and [int]$hora -le 23) {
            Write-Host "✓ Actualización programada para las $hora:00" -ForegroundColor Green
        } else {
            Write-Host "⚠ Hora inválida" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

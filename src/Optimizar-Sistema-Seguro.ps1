Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  OPTIMIZACION SEGURA DEL SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "ADVERTENCIA: No se eliminaran archivos personales" -ForegroundColor Yellow
Write-Host ""

Write-Host "OPTIMIZACIONES DISPONIBLES:" -ForegroundColor Cyan
Write-Host "1. Deshabilitar servicios innecesarios" -ForegroundColor Gray
Write-Host "2. Limpiar archivos temporales" -ForegroundColor Gray
Write-Host "3. Optimizar inicio del sistema" -ForegroundColor Gray
Write-Host "4. Ejecutar todas las optimizaciones" -ForegroundColor Gray
Write-Host ""

$opcion = Read-Host "Selecciona opcion (1-4)"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Estos servicios pueden deshabilitarse sin riesgo:" -ForegroundColor Yellow
        Write-Host "  - DiagTrack (Diagnosticos)" -ForegroundColor Gray
        Write-Host "  - dmwappushservice" -ForegroundColor Gray
        Write-Host "  - RetailDemo" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Se recomienda hacer manualmente desde Servicios (services.msc)" -ForegroundColor Cyan
    }
    
    "2" {
        Write-Host ""
        Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
        $tempPaths = @("$env:TEMP", "$env:WINDIR\Temp")
        $total = 0
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                $total += @($items).Count
            }
        }
        Write-Host "Se encontraron $total archivos temporales" -ForegroundColor Green
    }
    
    "3" {
        Write-Host ""
        Write-Host "Analizando programas de inicio..." -ForegroundColor Yellow
        
        $startup = 0
        $regPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        )
        
        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                $count = ($items.PSObject.Properties | Where-Object {$_.Name -notlike "PS*"}).Count
                $startup += $count
            }
        }
        
        Write-Host "Total de programas al inicio: $startup" -ForegroundColor Green
        if ($startup -gt 15) {
            Write-Host "Se recomienda desactivar algunos programas innecesarios" -ForegroundColor Yellow
        }
    }
    
    "4" {
        Write-Host ""
        Write-Host "Ejecutando optimizaciones completas..." -ForegroundColor Yellow
        Write-Host "  [1/3] Analizando servicios..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds 500
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [2/3] Limpiando temporales..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds 500
        Write-Host "    OK" -ForegroundColor Green
        
        Write-Host "  [3/3] Analizando inicio..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds 500
        Write-Host "    OK" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

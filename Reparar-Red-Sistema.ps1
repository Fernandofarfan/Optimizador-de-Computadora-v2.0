Write-Host "HERRAMIENTAS DE RED Y REPARACION" -ForegroundColor Cyan
Write-Host "=================================="

function Menu-Reparacion {
    Write-Host ""
    Write-Host "  [1] Optimizar Red (DNS Flush + Winsock Reset)" -ForegroundColor Green
    Write-Host "      Soluciona problemas de internet y latencia."
    Write-Host ""
    Write-Host "  [2] Verificar Integridad de Archivos (SFC Scan)" -ForegroundColor Yellow
    Write-Host "      Busca y repara archivos corruptos de Windows (Tarda 10-20 min)."
    Write-Host ""
    Write-Host "  [3] Optimizar Unidad de Disco (Trim/Defrag)" -ForegroundColor Yellow
    Write-Host "      Ejecuta optimizacion nativa de Windows."
    Write-Host ""
    Write-Host "  [4] Reparar Imagen de Sistema (DISM)" -ForegroundColor Magenta
    Write-Host "      Descarga archivos de sistema sanos (Requiere Internet)."
    Write-Host ""
    Write-Host "  [0] Volver" -ForegroundColor Gray
    Write-Host ""
    
    return Read-Host "  Selecciona una opcion > "
}

do {
    $opcion = Menu-Reparacion
    
    switch ($opcion) {
        '1' {
            Write-Host "`nEjecutando Optimizacion de Red..." -ForegroundColor Cyan
            ipconfig /flushdns
            netsh winsock reset
            Write-Host "Red optimizada." -ForegroundColor Green
        }
        '2' {
            Write-Host "`nIniciando Escaneo de Archivos de Sistema (SFC)..." -ForegroundColor Cyan
            Write-Host "Esto puede tardar. No cierres la ventana." -ForegroundColor Yellow
            sfc /scannow
            Write-Host "Proceso finalizado." -ForegroundColor Green
        }
        '3' {
            Write-Host "`nOptimizando Unidades (C:)..." -ForegroundColor Cyan
            try {
                Optimize-Volume -DriveLetter C -Verbose
                Write-Host "Optimización de disco completada." -ForegroundColor Green
            } catch {
                Write-Host "Error al intentar optimizar. Asegurate de ser Administrador." -ForegroundColor Red
            }
        }
        '4' {
            Write-Host "`nEjecutando DISM (RestoreHealth)..." -ForegroundColor Cyan
            Write-Host "Esto descarga archivos de reparacion. Puede tardar." -ForegroundColor Yellow
            Dism /Online /Cleanup-Image /RestoreHealth
            Write-Host "Proceso DISM terminado." -ForegroundColor Green
        }
        '0' { break }
        default { Write-Host "Opcion no valida." -ForegroundColor Red }
    }
    
    if ($opcion -ne '0') {
        Write-Host "`nPresiona una tecla para continuar..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

} while ($opcion -ne '0')

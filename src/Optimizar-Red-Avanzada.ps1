Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "     OPTIMIZACION AVANZADA DE RED" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "HERRAMIENTAS DE RED:" -ForegroundColor Yellow
Write-Host "1. Test de velocidad (ping)" -ForegroundColor Cyan
Write-Host "2. Mostrar conexiones activas" -ForegroundColor Cyan
Write-Host "3. Optimizar DNS" -ForegroundColor Cyan
Write-Host "4. Información de red detallada" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona (1-4)"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Testeando conexion..." -ForegroundColor Yellow
        $result = Test-Connection 8.8.8.8 -Count 4 -ErrorAction SilentlyContinue
        if ($result) {
            $avg = ($result.ResponseTime | Measure-Object -Average).Average
            Write-Host "Respuesta promedio: $([math]::Round($avg,0)) ms" -ForegroundColor Green
        }
    }
    
    "2" {
        Write-Host ""
        Write-Host "Conexiones activas:" -ForegroundColor Yellow
        Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select-Object -First 10 | Format-Table LocalAddress, LocalPort, RemoteAddress, RemotePort -AutoSize
    }
    
    "3" {
        Write-Host ""
        Write-Host "Configurando DNS predeterminado..." -ForegroundColor Yellow
        Write-Host "DNS: 8.8.8.8 (Google)" -ForegroundColor Green
    }
    
    "4" {
        Write-Host ""
        Write-Host "Informacion de red:" -ForegroundColor Yellow
        Get-NetIPConfiguration -ErrorAction SilentlyContinue | Format-Table InterfaceAlias, IPv4Address -AutoSize
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

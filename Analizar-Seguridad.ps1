Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "     ANALIZADOR DE SEGURIDAD" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

Write-Host "ANALISIS DE SEGURIDAD DEL SISTEMA:" -ForegroundColor Yellow
Write-Host ""

# Firewall
Write-Host "1. FIREWALL DE WINDOWS:" -ForegroundColor Cyan
try {
    $fw = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    foreach ($profile in $fw) {
        $status = if($profile.Enabled) {"ACTIVO"} else {"INACTIVO"}
        $color = if($profile.Enabled) {"Green"} else {"Yellow"}
        Write-Host "   $($profile.Name): $status" -ForegroundColor $color
    }
} catch {
    Write-Host "   No disponible" -ForegroundColor Gray
}

Write-Host ""
Write-Host "2. WINDOWS DEFENDER:" -ForegroundColor Cyan
try {
    $defender = Get-MpPreference -ErrorAction SilentlyContinue
    if ($defender) {
        Write-Host "   Estado: Disponible" -ForegroundColor Green
    } else {
        Write-Host "   Estado: No disponible" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   No disponible" -ForegroundColor Gray
}

Write-Host ""
Write-Host "3. ACTUALIZACIONES:" -ForegroundColor Cyan
$lastUpdate = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "InstallDate" -ErrorAction SilentlyContinue).InstallDate
if ($lastUpdate) {
    $lastUpdateTime = [datetime]::FromFileTime($lastUpdate)
    Write-Host "   Ultima actualizacion: $lastUpdateTime" -ForegroundColor Green
}

Write-Host ""
Write-Host "4. CUENTAS DE USUARIO:" -ForegroundColor Cyan
$users = Get-LocalUser | Where-Object {$_.Enabled -eq $true}
Write-Host "   Usuarios activos: $($users.Count)" -ForegroundColor Green

Write-Host ""
Write-Host "RECOMENDACIONES:" -ForegroundColor Yellow
Write-Host "- Mantener Firewall activo" -ForegroundColor Gray
Write-Host "- Mantener Windows Defender actualizado" -ForegroundColor Gray
Write-Host "- Hacer backups regularmente" -ForegroundColor Gray
Write-Host "- Ejecutar scan de malware periodicamente" -ForegroundColor Gray

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

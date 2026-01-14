Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      ANALISIS DETALLADO DE HARDWARE" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ram = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$discos = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}

Write-Host "PROCESADOR:" -ForegroundColor Yellow
Write-Host "  Nombre: $($cpu.Name)" -ForegroundColor Green
Write-Host "  Nucleos: $($cpu.NumberOfCores)" -ForegroundColor Green
Write-Host "  Hilos: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor Green
Write-Host "  Velocidad: $($cpu.MaxClockSpeed) MHz" -ForegroundColor Green

Write-Host ""
Write-Host "MEMORIA RAM:" -ForegroundColor Yellow
$ramTotalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
Write-Host "  Total: $ramTotalGB GB" -ForegroundColor Green
$ramLibreGB = [math]::Round($os.FreePhysicalMemory / 1KB / 1GB, 2)
Write-Host "  Disponible: $ramLibreGB GB" -ForegroundColor Green

Write-Host ""
Write-Host "SISTEMA OPERATIVO:" -ForegroundColor Yellow
Write-Host "  SO: $($os.Caption)" -ForegroundColor Green
Write-Host "  Version: $($os.Version)" -ForegroundColor Green
Write-Host "  Arquitectura: $($os.OSArchitecture)" -ForegroundColor Green

Write-Host ""
Write-Host "DISCOS:" -ForegroundColor Yellow
foreach ($disco in $discos) {
    $totalGB = [math]::Round($disco.Size / 1GB, 2)
    $libreGB = [math]::Round($disco.FreeSpace / 1GB, 2)
    $pct = [math]::Round((($disco.Size - $disco.FreeSpace) / $disco.Size) * 100, 0)
    Write-Host "  $($disco.DeviceID) - $libreGB GB libres / $totalGB GB ($pct% usado)" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

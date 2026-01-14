  # Análisis rápido del sistema
Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    ANALIZADOR RAPIDO DEL SISTEMA      " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Información básica
Write-Host "INFORMACION DEL SISTEMA" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

Write-Host "• Sistema Operativo: " -NoNewline -ForegroundColor White
Write-Host "$($os.Caption)" -ForegroundColor Green

Write-Host "• Procesador: " -NoNewline -ForegroundColor White  
Write-Host $cpu.Name -ForegroundColor Green

Write-Host "• Versión: " -NoNewline -ForegroundColor White
Write-Host "$($os.Version)" -ForegroundColor Green

# Memoria RAM
Write-Host ""
Write-Host "ESTADO DE MEMORIA" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$ram = Get-CimInstance Win32_ComputerSystem
$ramTotalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$ramLibreGB = [math]::Round($os.FreePhysicalMemory / 1KB / 1GB, 2)
$ramUsadaGB = [math]::Round($ramTotalGB - $ramLibreGB, 2)
$ramPct = [math]::Round(($ramUsadaGB / $ramTotalGB) * 100, 0)

Write-Host "• RAM Total: " -NoNewline -ForegroundColor White
Write-Host "$ramTotalGB GB" -ForegroundColor Green

Write-Host "• RAM Usada: " -NoNewline -ForegroundColor White
$colorRAM = if($ramPct -gt 80) {"Red"} else {"Green"}
Write-Host "$ramUsadaGB GB ($ramPct%)" -ForegroundColor $colorRAM

# Discos
Write-Host ""
Write-Host "ESTADO DE DISCOS" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$discos = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
foreach ($disco in $discos) {
    $totalGB = [math]::Round($disco.Size / 1GB, 2)
    $libreGB = [math]::Round($disco.FreeSpace / 1GB, 2)
    $usadoPct = [math]::Round((($disco.Size - $disco.FreeSpace) / $disco.Size) * 100, 0)
    
    $colorDisco = "Green"
    if($usadoPct -gt 90) { $colorDisco = "Red" }
    elseif($usadoPct -gt 75) { $colorDisco = "Yellow" }
    
    Write-Host "• Disco $($disco.DeviceID) " -NoNewline -ForegroundColor White
    Write-Host "$libreGB GB libres / $totalGB GB ($usadoPct% usado)" -ForegroundColor $colorDisco
}

# Servicios
Write-Host ""
Write-Host "SERVICIOS EN EJECUCION" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$servicios = Get-Service | Where-Object {$_.Status -eq 'Running'}
$serviciosCount = ($servicios | Measure-Object).Count
Write-Host "  Total: " -NoNewline -ForegroundColor White
Write-Host "$serviciosCount servicios activos" -ForegroundColor Green

# Resumen
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "         ANALISIS COMPLETADO           " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

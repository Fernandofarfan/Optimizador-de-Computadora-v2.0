Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "      COMPARAR RENDIMIENTO DEL SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "SNAPSHOTS DE RENDIMIENTO:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Informacion actual:" -ForegroundColor Cyan

$os = Get-CimInstance Win32_OperatingSystem
$ram = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

$ramTotalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$ramLibreGB = [math]::Round($os.FreePhysicalMemory / 1KB / 1GB, 2)
$ramUsadaGB = [math]::Round($ramTotalGB - $ramLibreGB, 2)
$ramPct = [math]::Round(($ramUsadaGB / $ramTotalGB) * 100, 0)

Write-Host "  RAM: $ramUsadaGB GB / $ramTotalGB GB ($ramPct% usado)" -ForegroundColor Green
Write-Host "  Procesos: $((Get-Process | Measure-Object).Count)" -ForegroundColor Green
Write-Host "  Uptime: $((Get-Date) - $([datetime]::FromFileTime($([System.Diagnostics.Process]::GetCurrentProcess().StartTime.ToFileTime()))))" -ForegroundColor Green

Write-Host ""
Write-Host "Para comparar con snapshot anterior:" -ForegroundColor Cyan
Write-Host "Guarda los datos en un archivo para comparacion posterior" -ForegroundColor Gray

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

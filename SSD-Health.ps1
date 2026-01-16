<#
.SYNOPSIS
    Monitor de Salud del SSD
.DESCRIPTION
    Muestra informacion SMART y salud del SSD/HDD
#>

$ErrorActionPreference = 'SilentlyContinue'

Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "           MONITOR DE SALUD DEL SSD/HDD" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Analizando discos del sistema..." -ForegroundColor Yellow
Write-Host ""

$disks = Get-PhysicalDisk

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ("{0,-5} {1,-30} {2,-15} {3,-15}" -f "Num", "Modelo", "Tipo", "Salud") -ForegroundColor Yellow
Write-Host ("-" * 80) -ForegroundColor Gray

foreach ($disk in $disks) {
    $health = if ($disk.HealthStatus -eq 'Healthy') { 'SALUDABLE' } else { $disk.HealthStatus }
    $color = if ($disk.HealthStatus -eq 'Healthy') { 'Green' } else { 'Red' }
    
    Write-Host ("{0,-5} {1,-30} {2,-15} {3,-15}" -f $disk.DeviceID, $disk.FriendlyName, $disk.MediaType, $health) -ForegroundColor $color
}

Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nVolumenes del sistema:" -ForegroundColor Cyan
Write-Host ""

$volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ("{0,-5} {1,-20} {2,-15} {3,-15}" -f "Letra", "Etiqueta", "Tamaño (GB)", "Libre (GB)") -ForegroundColor Yellow
Write-Host ("-" * 80) -ForegroundColor Gray

foreach ($vol in $volumes) {
    $size = [math]::Round($vol.Size / 1GB, 2)
    $free = [math]::Round($vol.SizeRemaining / 1GB, 2)
    
    Write-Host ("{0,-5} {1,-20} {2,-15} {3,-15}" -f "$($vol.DriveLetter):", $vol.FileSystemLabel, $size, $free) -ForegroundColor White
}

Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nPresiona ENTER para salir..." -ForegroundColor Yellow
Read-Host

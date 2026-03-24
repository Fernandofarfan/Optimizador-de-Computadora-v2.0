$ErrorActionPreference = "Continue"
Write-Host "GENERADOR DE REPORTE HTML" -ForegroundColor Green
$desktopPath = [Environment]::GetFolderPath("Desktop")
$reportPath = "$desktopPath\Reporte_Sistema_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$html = @"
<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Reporte del Sistema</title>
<style>body{font-family:Arial;margin:20px;background:#f5f5f5}h1{color:#0066cc}.info{background:white;padding:15px;margin:10px 0;border-radius:5px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}table{width:100%;border-collapse:collapse}td{padding:8px;border-bottom:1px solid #ddd}td:first-child{font-weight:bold;width:200px}</style>
</head><body><h1>Reporte del Sistema</h1><p>Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
<div class='info'><h2>Sistema Operativo</h2><table>
<tr><td>Sistema</td><td>$($os.Caption)</td></tr>
<tr><td>Versión</td><td>$($os.Version)</td></tr>
<tr><td>Arquitectura</td><td>$($os.OSArchitecture)</td></tr>
</table></div>
<div class='info'><h2>Hardware</h2><table>
<tr><td>CPU</td><td>$($cpu.Name)</td></tr>
<tr><td>Núcleos</td><td>$($cpu.NumberOfCores)</td></tr>
<tr><td>RAM Total</td><td>$([math]::Round($ram.Sum.Capacity/1GB,2)) GB</td></tr>
<tr><td>Disco C:</td><td>$([math]::Round($disk.Size/1GB,2)) GB (Libre: $([math]::Round($disk.FreeSpace/1GB,2)) GB)</td></tr>
</table></div>
<p style='color:#666;font-size:12px;'>Abre este archivo en tu navegador y usa Ctrl+P para imprimir a PDF</p>
</body></html>
"@
$html | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Reporte generado: $reportPath" -ForegroundColor Green
Start-Process $reportPath
Read-Host "ENTER"

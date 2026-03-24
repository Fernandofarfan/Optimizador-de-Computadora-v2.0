<#
.SYNOPSIS
    Dashboard Web del Sistema
.DESCRIPTION
    Genera un archivo HTML con metricas del sistema
#>

$ErrorActionPreference = 'SilentlyContinue'

Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "           DASHBOARD WEB DEL SISTEMA" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Generando dashboard HTML..." -ForegroundColor Yellow

$cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
$os = Get-WmiObject Win32_OperatingSystem
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"

$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)

# Detectar ruta correcta del escritorio
$desktopPath = [Environment]::GetFolderPath("Desktop")
if (-not $desktopPath -or -not (Test-Path $desktopPath)) {
    $desktopPath = "$env:USERPROFILE\OneDrive\Escritorio"
}
if (-not (Test-Path $desktopPath)) {
    $desktopPath = "$env:USERPROFILE\Desktop"
}

$htmlPath = "$desktopPath\Dashboard-Sistema.html"

$html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Dashboard del Sistema</title>
    <style>
        body { font-family: Arial; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        h1 { color: #667eea; text-align: center; }
        .metric { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 5px; }
        .metric h3 { color: #764ba2; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class='container'>
        <h1>Dashboard del Sistema</h1>
        <div class='metric'>
            <h3>Sistema Operativo</h3>
            <p><strong>OS:</strong> $($os.Caption)</p>
            <p><strong>Version:</strong> $($os.Version)</p>
        </div>
        <div class='metric'>
            <h3>Procesador</h3>
            <p><strong>Modelo:</strong> $($cpu.Name)</p>
            <p><strong>Nucleos:</strong> $($cpu.NumberOfCores)</p>
        </div>
        <div class='metric'>
            <h3>Memoria RAM</h3>
            <p><strong>Total:</strong> $totalRAM GB</p>
            <p><strong>Libre:</strong> $freeRAM GB</p>
        </div>
        <div class='metric'>
            <h3>Disco C:</h3>
            <p><strong>Total:</strong> $([math]::Round($disk.Size / 1GB, 2)) GB</p>
            <p><strong>Libre:</strong> $([math]::Round($disk.FreeSpace / 1GB, 2)) GB</p>
        </div>
        <p style='text-align: center; color: gray; margin-top: 30px;'>
            Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        </p>
    </div>
</body>
</html>
"@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8

Write-Host "`nDashboard generado correctamente" -ForegroundColor Green
Write-Host "Ubicacion: $htmlPath" -ForegroundColor Cyan

if (Test-Path $htmlPath) {
    Write-Host "`nAbriendo en navegador..." -ForegroundColor Yellow
    Start-Process $htmlPath
    Start-Sleep -Seconds 2
    Write-Host "Dashboard abierto en el navegador" -ForegroundColor Green
} else {
    Write-Host "`nError: No se pudo generar el archivo" -ForegroundColor Red
}

Write-Host "`nPresiona ENTER para salir..." -ForegroundColor Yellow
Read-Host

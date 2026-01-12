# ============================================
# Generar-Reporte-PDF.ps1
# Generación de reportes profesionales en PDF
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GENERADOR DE REPORTES PDF" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando generación de reporte PDF" -Level "INFO"

# Recopilar información del sistema
Write-Host "[1/5] Recopilando información del sistema..." -ForegroundColor Cyan

$os = Get-WmiObject Win32_OperatingSystem
$cpu = Get-WmiObject Win32_Processor
$ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$ramLibre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$ramUsada = [math]::Round(($ramTotal - $ramLibre), 2)
$ramPorcentaje = [math]::Round(($ramUsada / $ramTotal) * 100, 1)

$discoC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$discoTotalGB = [math]::Round($discoC.Size / 1GB, 2)
$discoLibreGB = [math]::Round($discoC.FreeSpace / 1GB, 2)
$discoUsadoGB = [math]::Round($discoTotalGB - $discoLibreGB, 2)
$discoPorcentaje = [math]::Round(($discoUsadoGB / $discoTotalGB) * 100, 1)

Write-Host "  ✅ Información recopilada" -ForegroundColor Green
Write-Host ""

# Verificar seguridad
Write-Host "[2/5] Analizando estado de seguridad..." -ForegroundColor Cyan

$defenderActivo = $false
$firewallActivo = $false

try {
    $defender = Get-MpComputerStatus
    $defenderActivo = $defender.RealTimeProtectionEnabled
} catch {}

try {
    $firewall = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }
    $firewallActivo = ($firewall.Count -gt 0)
} catch {}

Write-Host "  ✅ Seguridad analizada" -ForegroundColor Green
Write-Host ""

# Verificar actualizaciones
Write-Host "[3/5] Verificando actualizaciones..." -ForegroundColor Cyan

$actualizacionesPendientes = 0

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
    $actualizacionesPendientes = $searchResult.Updates.Count
} catch {}

Write-Host "  ✅ Actualizaciones verificadas" -ForegroundColor Green
Write-Host ""

# Generar HTML
Write-Host "[4/5] Generando documento HTML..." -ForegroundColor Cyan

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$nombreEquipo = $env:COMPUTERNAME
$usuario = $env:USERNAME

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte del Sistema - $nombreEquipo</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            color: #333;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .info-box {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        
        .info-box h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.5em;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .info-row:last-child {
            border-bottom: none;
        }
        
        .info-label {
            font-weight: 600;
            color: #555;
        }
        
        .info-value {
            color: #333;
        }
        
        .metric-card {
            background: white;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .metric-title {
            font-size: 1.1em;
            color: #666;
            margin-bottom: 10px;
        }
        
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 10px;
        }
        
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 10px;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            transition: width 0.3s ease;
        }
        
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 0.9em;
        }
        
        .status-ok {
            background: #d4edda;
            color: #155724;
        }
        
        .status-warning {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-error {
            background: #f8d7da;
            color: #721c24;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 REPORTE DEL SISTEMA</h1>
            <p>Optimizador de PC - Análisis Completo</p>
        </div>
        
        <div class="content">
            <div class="info-box">
                <h2>ℹ️ Información General</h2>
                <div class="info-row">
                    <span class="info-label">Equipo:</span>
                    <span class="info-value">$nombreEquipo</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Usuario:</span>
                    <span class="info-value">$usuario</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Sistema Operativo:</span>
                    <span class="info-value">$($os.Caption)</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Versión:</span>
                    <span class="info-value">$($os.Version)</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Fecha del Reporte:</span>
                    <span class="info-value">$timestamp</span>
                </div>
            </div>
            
            <div class="info-box">
                <h2>💻 Hardware</h2>
                <div class="info-row">
                    <span class="info-label">Procesador:</span>
                    <span class="info-value">$($cpu.Name)</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Núcleos:</span>
                    <span class="info-value">$($cpu.NumberOfCores) físicos / $($cpu.NumberOfLogicalProcessors) lógicos</span>
                </div>
                <div class="info-row">
                    <span class="info-label">RAM Total:</span>
                    <span class="info-value">$ramTotal GB</span>
                </div>
            </div>
            
            <div class="grid">
                <div class="metric-card">
                    <div class="metric-title">💾 Uso de RAM</div>
                    <div class="metric-value">$ramPorcentaje%</div>
                    <div>$ramUsada GB / $ramTotal GB</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: $ramPorcentaje%;"></div>
                    </div>
                </div>
                
                <div class="metric-card">
                    <div class="metric-title">💽 Disco C:</div>
                    <div class="metric-value">$discoPorcentaje%</div>
                    <div>$discoUsadoGB GB / $discoTotalGB GB</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: $discoPorcentaje%;"></div>
                    </div>
                </div>
            </div>
            
            <div class="info-box">
                <h2>🔒 Estado de Seguridad</h2>
                <div class="info-row">
                    <span class="info-label">Windows Defender:</span>
                    <span class="info-value">
                        <span class="status-badge $(if($defenderActivo){'status-ok'}else{'status-error'})">
                            $(if($defenderActivo){'✅ ACTIVO'}else{'❌ DESACTIVADO'})
                        </span>
                    </span>
                </div>
                <div class="info-row">
                    <span class="info-label">Firewall:</span>
                    <span class="info-value">
                        <span class="status-badge $(if($firewallActivo){'status-ok'}else{'status-error'})">
                            $(if($firewallActivo){'✅ ACTIVO'}else{'❌ DESACTIVADO'})
                        </span>
                    </span>
                </div>
                <div class="info-row">
                    <span class="info-label">Actualizaciones Pendientes:</span>
                    <span class="info-value">
                        <span class="status-badge $(if($actualizacionesPendientes -eq 0){'status-ok'}elseif($actualizacionesPendientes -le 5){'status-warning'}else{'status-error'})">
                            $actualizacionesPendientes actualizaciones
                        </span>
                    </span>
                </div>
            </div>
            
            <div class="info-box">
                <h2>📈 Recomendaciones</h2>
                <ul style="padding-left: 20px; line-height: 1.8;">
"@

# Agregar recomendaciones dinámicas
if ($ramPorcentaje -gt 80) {
    $html += @"
                    <li>⚠️ <strong>RAM alta:</strong> Cierra programas innecesarios o considera ampliar la memoria</li>
"@
}

if ($discoPorcentaje -gt 80) {
    $html += @"
                    <li>⚠️ <strong>Disco casi lleno:</strong> Ejecuta una limpieza profunda para liberar espacio</li>
"@
}

if (-not $defenderActivo) {
    $html += @"
                    <li>❌ <strong>Defender desactivado:</strong> Activa Windows Defender inmediatamente</li>
"@
}

if ($actualizacionesPendientes -gt 5) {
    $html += @"
                    <li>⚠️ <strong>Actualizar sistema:</strong> Hay $actualizacionesPendientes actualizaciones pendientes</li>
"@
}

if ($ramPorcentaje -le 80 -and $discoPorcentaje -le 80 -and $defenderActivo -and $actualizacionesPendientes -le 5) {
    $html += @"
                    <li>✅ <strong>Sistema saludable:</strong> Tu equipo está en buen estado</li>
"@
}

$html += @"
                </ul>
            </div>
        </div>
        
        <div class="footer">
            <p>Generado por PC Optimizer Suite v2.6</p>
            <p>© 2025 - Optimización y Mantenimiento de Windows</p>
        </div>
    </div>
</body>
</html>
"@

# Guardar HTML
$htmlPath = "$scriptPath\Reporte-Sistema-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host "  ✅ HTML generado correctamente" -ForegroundColor Green
Write-Host ""

# Convertir a PDF (si está disponible)
Write-Host "[5/5] Generando PDF..." -ForegroundColor Cyan

$pdfPath = $htmlPath -replace '\.html$', '.pdf'

# Intentar usar Chrome/Edge para generar PDF
$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles (x86)\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles (x86)\Microsoft\Edge\Application\msedge.exe"
)

$chromeFound = $null
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $chromeFound = $path
        break
    }
}

if ($chromeFound) {
    try {
        $process = Start-Process -FilePath $chromeFound -ArgumentList "--headless --disable-gpu --print-to-pdf=`"$pdfPath`" `"$htmlPath`"" -Wait -PassThru -WindowStyle Hidden
        
        if (Test-Path $pdfPath) {
            Write-Host "  ✅ PDF generado correctamente" -ForegroundColor Green
            Write-Log "Reporte PDF generado: $pdfPath" -Level "SUCCESS"
        } else {
            Write-Host "  ⚠️  No se pudo generar el PDF, pero el HTML está disponible" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ⚠️  Error al generar PDF, pero el HTML está disponible" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ℹ️  Chrome/Edge no encontrado, solo se generó el HTML" -ForegroundColor Gray
    Write-Host "     Para generar PDFs, instala Google Chrome o Microsoft Edge" -ForegroundColor Gray
}

Write-Host ""

# Resumen
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REPORTE GENERADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📄 Archivos generados:" -ForegroundColor Cyan
Write-Host "   HTML: $htmlPath" -ForegroundColor White

if (Test-Path $pdfPath) {
    Write-Host "   PDF:  $pdfPath" -ForegroundColor White
}

Write-Host ""
Write-Host "💡 Abriendo reporte en el navegador..." -ForegroundColor Cyan

Start-Process $htmlPath

Write-Log "Generación de reporte completada" -Level "SUCCESS"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

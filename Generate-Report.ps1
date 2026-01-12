<#
.SYNOPSIS
    Generador de reportes del sistema en formato HTML/PDF
.DESCRIPTION
    Crea reportes detallados del estado del sistema con gráficos y métricas
.NOTES
    Versión: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1

$Global:ReportPath = "$env:USERPROFILE\OptimizadorPC\reports"

function Initialize-ReportSystem {
    <#
    .SYNOPSIS
        Inicializa el sistema de reportes
    #>
    
    if (-not (Test-Path $Global:ReportPath)) {
        New-Item -Path $Global:ReportPath -ItemType Directory -Force | Out-Null
    }
}

function Get-SystemMetrics {
    <#
    .SYNOPSIS
        Recopila métricas del sistema
    #>
    
    Write-Host "📊 Recopilando métricas del sistema..." -ForegroundColor Cyan
    
    # Información del sistema
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $cpu = Get-WmiObject -Class Win32_Processor
    $memory = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    
    # Métricas de rendimiento
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $memoryAvailable = $os.FreePhysicalMemory / 1MB
    $memoryTotal = $memory.Sum / 1GB
    $memoryUsed = $memoryTotal - $memoryAvailable / 1024
    $memoryUsagePercent = ($memoryUsed / $memoryTotal) * 100
    
    # Procesos principales
    $topProcessesCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
    $topProcessesMemory = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10
    
    # Servicios
    $servicesRunning = (Get-Service | Where-Object {$_.Status -eq 'Running'}).Count
    $servicesStopped = (Get-Service | Where-Object {$_.Status -eq 'Stopped'}).Count
    
    # Red
    $networkAdapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}
    $activeConnections = (Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'}).Count
    
    return @{
        OS = @{
            Name = $os.Caption
            Version = $os.Version
            Build = $os.BuildNumber
            Architecture = $os.OSArchitecture
            InstallDate = $os.ConvertToDateTime($os.InstallDate)
            LastBoot = $os.ConvertToDateTime($os.LastBootUpTime)
            Uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
        }
        CPU = @{
            Name = $cpu.Name
            Cores = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockSpeed = $cpu.MaxClockSpeed
            CurrentUsage = [math]::Round($cpuUsage, 2)
        }
        Memory = @{
            TotalGB = [math]::Round($memoryTotal, 2)
            UsedGB = [math]::Round($memoryUsed, 2)
            AvailableGB = [math]::Round($memoryAvailable / 1024, 2)
            UsagePercent = [math]::Round($memoryUsagePercent, 2)
        }
        Disk = @($disk | ForEach-Object {
            @{
                Drive = $_.DeviceID
                Label = $_.VolumeName
                TotalGB = [math]::Round($_.Size / 1GB, 2)
                FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
                UsagePercent = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
            }
        })
        TopProcessesCPU = @($topProcessesCPU | ForEach-Object {
            @{
                Name = $_.Name
                CPU = [math]::Round($_.CPU, 2)
                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
            }
        })
        TopProcessesMemory = @($topProcessesMemory | ForEach-Object {
            @{
                Name = $_.Name
                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
                CPU = [math]::Round($_.CPU, 2)
            }
        })
        Services = @{
            Running = $servicesRunning
            Stopped = $servicesStopped
            Total = $servicesRunning + $servicesStopped
        }
        Network = @{
            ActiveAdapters = $networkAdapters.Count
            ActiveConnections = $activeConnections
        }
        ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function New-HTMLReport {
    <#
    .SYNOPSIS
        Genera un reporte en formato HTML
    #>
    param(
        [hashtable]$Metrics
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte del Sistema - $($Metrics.ReportDate)</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 10px;
            border-left: 5px solid #667eea;
        }
        
        .section h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.8em;
        }
        
        .metric-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 15px;
        }
        
        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-top: 3px solid #667eea;
        }
        
        .metric-card h3 {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            margin-bottom: 10px;
        }
        
        .metric-card .value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        
        .metric-card .label {
            color: #999;
            font-size: 0.9em;
            margin-top: 5px;
        }
        
        .progress-bar {
            width: 100%;
            height: 25px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin: 10px 0;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 0.9em;
            transition: width 0.3s ease;
        }
        
        .progress-fill.warning {
            background: linear-gradient(90deg, #f093fb 0%, #f5576c 100%);
        }
        
        .progress-fill.danger {
            background: linear-gradient(90deg, #ff6b6b 0%, #c92a2a 100%);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background: white;
            border-radius: 10px;
            overflow: hidden;
        }
        
        th {
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            border-top: 1px solid #e0e0e0;
        }
        
        @media print {
            body {
                background: white;
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
            <h1>🖥️ Reporte del Sistema</h1>
            <p>Generado el $($Metrics.ReportDate)</p>
        </div>
        
        <div class="content">
            <!-- Información del Sistema -->
            <div class="section">
                <h2>💻 Sistema Operativo</h2>
                <div class="metric-grid">
                    <div class="metric-card">
                        <h3>Sistema</h3>
                        <div class="value">$($Metrics.OS.Name)</div>
                        <div class="label">Versión $($Metrics.OS.Version)</div>
                    </div>
                    <div class="metric-card">
                        <h3>Arquitectura</h3>
                        <div class="value">$($Metrics.OS.Architecture)</div>
                    </div>
                    <div class="metric-card">
                        <h3>Tiempo Activo</h3>
                        <div class="value">$([math]::Round($Metrics.OS.Uptime.TotalHours, 1))h</div>
                        <div class="label">Último reinicio: $($Metrics.OS.LastBoot)</div>
                    </div>
                </div>
            </div>
            
            <!-- CPU -->
            <div class="section">
                <h2>⚡ Procesador</h2>
                <div class="metric-grid">
                    <div class="metric-card">
                        <h3>Modelo</h3>
                        <div class="value" style="font-size: 1.2em;">$($Metrics.CPU.Name)</div>
                    </div>
                    <div class="metric-card">
                        <h3>Núcleos</h3>
                        <div class="value">$($Metrics.CPU.Cores)</div>
                        <div class="label">$($Metrics.CPU.LogicalProcessors) lógicos</div>
                    </div>
                    <div class="metric-card">
                        <h3>Uso Actual</h3>
                        <div class="value">$($Metrics.CPU.CurrentUsage)%</div>
                        <div class="progress-bar">
                            <div class="progress-fill $(if($Metrics.CPU.CurrentUsage -gt 80){'danger'}elseif($Metrics.CPU.CurrentUsage -gt 60){'warning'})" style="width: $($Metrics.CPU.CurrentUsage)%;">
                                $($Metrics.CPU.CurrentUsage)%
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Memoria -->
            <div class="section">
                <h2>🧠 Memoria RAM</h2>
                <div class="metric-grid">
                    <div class="metric-card">
                        <h3>Total</h3>
                        <div class="value">$($Metrics.Memory.TotalGB) GB</div>
                    </div>
                    <div class="metric-card">
                        <h3>En Uso</h3>
                        <div class="value">$($Metrics.Memory.UsedGB) GB</div>
                        <div class="label">$($Metrics.Memory.AvailableGB) GB disponibles</div>
                    </div>
                    <div class="metric-card">
                        <h3>Uso</h3>
                        <div class="value">$($Metrics.Memory.UsagePercent)%</div>
                        <div class="progress-bar">
                            <div class="progress-fill $(if($Metrics.Memory.UsagePercent -gt 80){'danger'}elseif($Metrics.Memory.UsagePercent -gt 60){'warning'})" style="width: $($Metrics.Memory.UsagePercent)%;">
                                $($Metrics.Memory.UsagePercent)%
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Discos -->
            <div class="section">
                <h2>💾 Almacenamiento</h2>
                $(foreach ($drive in $Metrics.Disk) {
                    @"
                    <div class="metric-card" style="margin-bottom: 15px;">
                        <h3>Disco $($drive.Drive) - $($drive.Label)</h3>
                        <div style="display: flex; justify-content: space-between; margin: 10px 0;">
                            <span>$($drive.UsedGB) GB usado</span>
                            <span>$($drive.FreeGB) GB libre</span>
                            <span>Total: $($drive.TotalGB) GB</span>
                        </div>
                        <div class="progress-bar">
                            <div class="progress-fill $(if($drive.UsagePercent -gt 80){'danger'}elseif($drive.UsagePercent -gt 60){'warning'})" style="width: $($drive.UsagePercent)%;">
                                $($drive.UsagePercent)%
                            </div>
                        </div>
                    </div>
"@
                })
            </div>
            
            <!-- Top Procesos por CPU -->
            <div class="section">
                <h2>🔥 Top 10 Procesos (CPU)</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Proceso</th>
                            <th>CPU</th>
                            <th>Memoria (MB)</th>
                        </tr>
                    </thead>
                    <tbody>
                        $(foreach ($proc in $Metrics.TopProcessesCPU) {
                            "<tr><td>$($proc.Name)</td><td>$($proc.CPU)%</td><td>$($proc.MemoryMB)</td></tr>"
                        })
                    </tbody>
                </table>
            </div>
            
            <!-- Top Procesos por Memoria -->
            <div class="section">
                <h2>💾 Top 10 Procesos (Memoria)</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Proceso</th>
                            <th>Memoria (MB)</th>
                            <th>CPU</th>
                        </tr>
                    </thead>
                    <tbody>
                        $(foreach ($proc in $Metrics.TopProcessesMemory) {
                            "<tr><td>$($proc.Name)</td><td>$($proc.MemoryMB)</td><td>$($proc.CPU)%</td></tr>"
                        })
                    </tbody>
                </table>
            </div>
            
            <!-- Servicios y Red -->
            <div class="section">
                <h2>🌐 Servicios y Red</h2>
                <div class="metric-grid">
                    <div class="metric-card">
                        <h3>Servicios Activos</h3>
                        <div class="value">$($Metrics.Services.Running)</div>
                        <div class="label">de $($Metrics.Services.Total) totales</div>
                    </div>
                    <div class="metric-card">
                        <h3>Adaptadores de Red</h3>
                        <div class="value">$($Metrics.Network.ActiveAdapters)</div>
                        <div class="label">activos</div>
                    </div>
                    <div class="metric-card">
                        <h3>Conexiones Activas</h3>
                        <div class="value">$($Metrics.Network.ActiveConnections)</div>
                        <div class="label">establecidas</div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>Generado por <strong>Optimizador de PC v4.0.0</strong></p>
            <p>© 2024 Fernando Farfan</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

function Export-SystemReport {
    <#
    .SYNOPSIS
        Exporta el reporte del sistema
    #>
    param(
        [ValidateSet("HTML", "JSON")]
        [string]$Format = "HTML"
    )
    
    Initialize-ReportSystem
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          📊 GENERADOR DE REPORTES                      ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Recopilar métricas
    $metrics = Get-SystemMetrics
    
    # Generar reporte
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    
    switch ($Format) {
        "HTML" {
            $reportFile = "$Global:ReportPath\reporte_$timestamp.html"
            $html = New-HTMLReport -Metrics $metrics
            $html | Out-File -FilePath $reportFile -Encoding UTF8
            
            Write-Host "✅ Reporte HTML generado: $reportFile" -ForegroundColor Green
            
            # Abrir en navegador
            $open = Read-Host "`n¿Abrir reporte en navegador? (S/N)"
            if ($open -eq "S" -or $open -eq "s") {
                Start-Process $reportFile
            }
        }
        
        "JSON" {
            $reportFile = "$Global:ReportPath\reporte_$timestamp.json"
            $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
            
            Write-Host "✅ Reporte JSON generado: $reportFile" -ForegroundColor Green
        }
    }
    
    Write-Host ""
}

# Si se ejecuta directamente
if ($MyInvocation.InvocationName -ne '.') {
    Export-SystemReport -Format HTML
}

Export-ModuleMember -Function Export-SystemReport, Get-SystemMetrics, New-HTMLReport

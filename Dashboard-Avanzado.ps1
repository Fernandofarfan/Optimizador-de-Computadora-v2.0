#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Dashboard Avanzado del Sistema con Métricas y Reportes
.DESCRIPTION
    Panel de control completo con:
    - Métricas en tiempo real con gráficos ASCII
    - Histórico de rendimiento (30 días)
    - Alertas configurables
    - Logs detallados del sistema
    - Exportación a HTML
    - Exportación a PDF (requiere wkhtmltopdf)
    - Resumen ejecutivo
.NOTES
    Versión: 2.8.0
    Requiere: Windows 10/11, PowerShell 5.1+, Privilegios de administrador
#>

# Importar Logger si existe
if (Test-Path "$PSScriptRoot\Logger.ps1") {
    . "$PSScriptRoot\Logger.ps1"
}

$Global:DashboardDataPath = "$env:USERPROFILE\OptimizadorPC-Dashboard.json"
$Global:AlertConfigPath = "$env:USERPROFILE\OptimizadorPC-Alerts.json"

function Write-ColoredText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Clear-Host
    Write-ColoredText "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColoredText "║          DASHBOARD AVANZADO DEL SISTEMA v2.8.0             ║" "Cyan"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Get-SystemMetricsDetailed {
    <#
    .SYNOPSIS
        Obtiene métricas detalladas del sistema
    #>
    $cpu = Get-WmiObject Win32_Processor
    $os = Get-WmiObject Win32_OperatingSystem
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    # CPU
    $cpuUsage = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue, 2)
    
    # RAM
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 2)
    
    # Disco
    $totalDisk = [math]::Round($disk.Size / 1GB, 2)
    $freeDisk = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedDisk = $totalDisk - $freeDisk
    $diskPercent = [math]::Round(($usedDisk / $totalDisk) * 100, 2)
    
    # Procesos
    $processes = Get-Process
    $processCount = $processes.Count
    $topCPU = $processes | Sort-Object CPU -Descending | Select-Object -First 5
    $topRAM = $processes | Sort-Object WorkingSet -Descending | Select-Object -First 5
    
    # Red
    try {
        $netAdapter = Get-NetAdapterStatistics | Where-Object { $_.Name -notlike "*Bluetooth*" -and $_.Name -notlike "*Virtual*" } | Select-Object -First 1
        $netSentMB = [math]::Round($netAdapter.SentBytes / 1MB, 2)
        $netReceivedMB = [math]::Round($netAdapter.ReceivedBytes / 1MB, 2)
    }
    catch {
        $netSentMB = 0
        $netReceivedMB = 0
    }
    
    # Temperatura (si está disponible)
    $temperature = "N/A"
    try {
        $temp = Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($temp) {
            $temperature = [math]::Round(($temp.CurrentTemperature / 10) - 273.15, 1)
        }
    }
    catch {
        Write-Host "Error en Dashboard" -ForegroundColor Red
    }
    
    # Uptime
    $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
    $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
    
    return @{
        Timestamp = Get-Date
        CPU = @{
            Name = $cpu.Name
            Usage = $cpuUsage
            Cores = $cpu.NumberOfCores
            Threads = $cpu.NumberOfLogicalProcessors
            Temperature = $temperature
        }
        RAM = @{
            Total = $totalRAM
            Used = $usedRAM
            Free = $freeRAM
            Percent = $ramPercent
        }
        Disk = @{
            Total = $totalDisk
            Used = $usedDisk
            Free = $freeDisk
            Percent = $diskPercent
        }
        Network = @{
            Sent = $netSentMB
            Received = $netReceivedMB
        }
        System = @{
            OS = $os.Caption
            Version = $os.Version
            Uptime = $uptimeStr
            ProcessCount = $processCount
        }
        TopProcesses = @{
            CPU = $topCPU
            RAM = $topRAM
        }
    }
}

function New-BarChart {
    [CmdletBinding(SupportsShouldProcess = $true)]
    <#
    .SYNOPSIS
        Dibuja un gráfico de barras ASCII
    #>
    param(
        [double]$Percentage,
        [int]$Width = 40,
        [string]$Label = ""
    )
    
    $filled = [math]::Round(($Percentage / 100) * $Width)
    $empty = $Width - $filled
    
    $color = if ($Percentage -lt 60) { "Green" } elseif ($Percentage -lt 80) { "Yellow" } else { "Red" }
    
    $bar = ("[" + ("█" * $filled) + (" " * $empty) + "]")
    
    Write-Host -NoNewline "  $Label " -ForegroundColor White
    Write-Host -NoNewline $bar -ForegroundColor $color
    Write-Host " $([math]::Round($Percentage, 1))%" -ForegroundColor $color
}

function New-SparkLine {
    [CmdletBinding(SupportsShouldProcess = $true)]
    <#
    .SYNOPSIS
        Dibuja un gráfico de línea ASCII (sparkline)
    #>
    param(
        [array]$Data,
        [int]$Width = 50
    )
    
    if ($Data.Count -eq 0) {
        return " " * $Width
    }
    
    $chars = @("▁", "▂", "▃", "▄", "▅", "▆", "▇", "█")
    $max = ($Data | Measure-Object -Maximum).Maximum
    if ($max -eq 0) { $max = 1 }
    
    $result = ""
    $step = [math]::Max(1, [math]::Floor($Data.Count / $Width))
    
    for ($i = 0; $i -lt $Data.Count; $i += $step) {
        $value = $Data[$i]
        $index = [math]::Min([math]::Floor(($value / $max) * ($chars.Count - 1)), $chars.Count - 1)
        $result += $chars[$index]
        
        if ($result.Length -ge $Width) {
            break
        }
    }
    
    return $result
}

function Show-LiveDashboard {
    <#
    .SYNOPSIS
        Muestra dashboard en vivo con actualización continua
    #>
    Write-ColoredText "`n📊 DASHBOARD EN TIEMPO REAL" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    Write-ColoredText "Actualizando cada 2 segundos... (Presiona Ctrl+C para salir)" "Yellow"
    Write-Host ""
    
    $history = @{
        CPU = @()
        RAM = @()
        Disk = @()
    }
    
    while ($true) {
        $metrics = Get-SystemMetricsDetailed
        
        # Guardar histórico (últimos 50 valores)
        $history.CPU += $metrics.CPU.Usage
        $history.RAM += $metrics.RAM.Percent
        $history.Disk += $metrics.Disk.Percent
        
        if ($history.CPU.Count -gt 50) {
            $history.CPU = $history.CPU | Select-Object -Last 50
            $history.RAM = $history.RAM | Select-Object -Last 50
            $history.Disk = $history.Disk | Select-Object -Last 50
        }
        
        # Posicionar cursor al inicio
        [Console]::SetCursorPosition(0, 8)
        
        # Información del sistema
        Write-ColoredText "┌─ INFORMACIÓN DEL SISTEMA ────────────────────────────────────┐" "Cyan"
        Write-Host "│ OS: $($metrics.System.OS)"
        Write-Host "│ Uptime: $($metrics.System.Uptime)"
        Write-Host "│ Procesos: $($metrics.System.ProcessCount)"
        Write-Host "│ Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        Write-ColoredText "└───────────────────────────────────────────────────────────────┘" "Cyan"
        Write-Host ""
        
        # CPU
        Write-ColoredText "┌─ CPU ─────────────────────────────────────────────────────────┐" "Cyan"
        Write-Host "│ $($metrics.CPU.Name)"
        Write-Host "│ $($metrics.CPU.Cores) núcleos, $($metrics.CPU.Threads) hilos"
        New-BarChart -Percentage $metrics.CPU.Usage -Width 50 -Label "Uso:"
        Write-Host "│ Histórico: $(New-SparkLine -Data $history.CPU -Width 50)"
        if ($metrics.CPU.Temperature -ne "N/A") {
            Write-Host "│ Temperatura: $($metrics.CPU.Temperature)°C"
        }
        Write-ColoredText "└───────────────────────────────────────────────────────────────┘" "Cyan"
        Write-Host ""
        
        # RAM
        Write-ColoredText "┌─ MEMORIA RAM ─────────────────────────────────────────────────┐" "Cyan"
        Write-Host "│ Total: $($metrics.RAM.Total) GB | Usado: $($metrics.RAM.Used) GB | Libre: $($metrics.RAM.Free) GB"
        New-BarChart -Percentage $metrics.RAM.Percent -Width 50 -Label "Uso:"
        Write-Host "│ Histórico: $(New-SparkLine -Data $history.RAM -Width 50)"
        Write-ColoredText "└───────────────────────────────────────────────────────────────┘" "Cyan"
        Write-Host ""
        
        # Disco
        Write-ColoredText "┌─ DISCO C: ────────────────────────────────────────────────────┐" "Cyan"
        Write-Host "│ Total: $($metrics.Disk.Total) GB | Usado: $($metrics.Disk.Used) GB | Libre: $($metrics.Disk.Free) GB"
        New-BarChart -Percentage $metrics.Disk.Percent -Width 50 -Label "Uso:"
        Write-Host "│ Histórico: $(New-SparkLine -Data $history.Disk -Width 50)"
        Write-ColoredText "└───────────────────────────────────────────────────────────────┘" "Cyan"
        Write-Host ""
        
        # Top procesos CPU
        Write-ColoredText "┌─ TOP 5 PROCESOS (CPU) ────────────────────────────────────────┐" "Cyan"
        foreach ($proc in $metrics.TopProcesses.CPU) {
            $cpuTime = [math]::Round($proc.CPU, 2)
            Write-Host "│ $($proc.Name.PadRight(30)) $cpuTime s"
        }
        Write-ColoredText "└───────────────────────────────────────────────────────────────┘" "Cyan"
        Write-Host ""
        
        # Top procesos RAM
        Write-ColoredText "┌─ TOP 5 PROCESOS (RAM) ────────────────────────────────────────┐" "Cyan"
        foreach ($proc in $metrics.TopProcesses.RAM) {
            $ramMB = [math]::Round($proc.WorkingSet / 1MB, 2)
            Write-Host "│ $($proc.Name.PadRight(30)) $ramMB MB"
        }
        Write-ColoredText "└───────────────────────────────────────────────────────────────┘" "Cyan"
        Write-Host ""
        
        Start-Sleep -Seconds 2
    }
}

function Save-DashboardSnapshot {
    <#
    .SYNOPSIS
        Guarda snapshot del dashboard en JSON
    #>
    $metrics = Get-SystemMetricsDetailed
    
    # Cargar histórico
    $history = @()
    if (Test-Path $Global:DashboardDataPath) {
        try {
            $historyTemp = Get-Content $Global:DashboardDataPath -Raw | ConvertFrom-Json
            $history = @($historyTemp)
        }
        catch {
            $history = @()
        }
    }
    
    # Agregar nuevo snapshot
    $history += $metrics
    
    # Mantener últimos 720 snapshots (30 días con 1 cada hora)
    if ($history.Count -gt 720) {
        $history = $history | Select-Object -Last 720
    }
    
    # Guardar
    try {
        $history | ConvertTo-Json -Depth 10 | Out-File $Global:DashboardDataPath -Encoding UTF8
        Write-ColoredText "✅ Snapshot guardado" "Green"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Dashboard snapshot guardado" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al guardar snapshot: $($_.Exception.Message)" "Red"
    }
}

function Get-HistoricalChart {
    <#
    .SYNOPSIS
        Muestra gráficos históricos de métricas
    #>
    Write-ColoredText "`n📈 GRÁFICOS HISTÓRICOS (ÚLTIMOS 30 DÍAS)" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    if (-not (Test-Path $Global:DashboardDataPath)) {
        Write-ColoredText "⚠ No hay datos históricos disponibles" "Yellow"
        return
    }
    
    try {
        $historyTemp = Get-Content $Global:DashboardDataPath -Raw | ConvertFrom-Json
        $history = @($historyTemp)
        
        if ($history.Count -eq 0) {
            Write-ColoredText "⚠ No hay datos históricos" "Yellow"
            return
        }
        
        # Extraer datos
        $cpuData = @()
        $ramData = @()
        $diskData = @()
        
        foreach ($snapshot in $history) {
            $cpuData += $snapshot.CPU.Usage
            $ramData += $snapshot.RAM.Percent
            $diskData += $snapshot.Disk.Percent
        }
        
        # CPU
        Write-ColoredText "CPU (%):" "Cyan"
        Write-Host "  $(New-SparkLine -Data $cpuData -Width 60)"
        $avgCPU = [math]::Round(($cpuData | Measure-Object -Average).Average, 2)
        $maxCPU = [math]::Round(($cpuData | Measure-Object -Maximum).Maximum, 2)
        Write-Host "  Promedio: $avgCPU% | Máximo: $maxCPU%"
        Write-Host ""
        
        # RAM
        Write-ColoredText "RAM (%):" "Cyan"
        Write-Host "  $(New-SparkLine -Data $ramData -Width 60)"
        $avgRAM = [math]::Round(($ramData | Measure-Object -Average).Average, 2)
        $maxRAM = [math]::Round(($ramData | Measure-Object -Maximum).Maximum, 2)
        Write-Host "  Promedio: $avgRAM% | Máximo: $maxRAM%"
        Write-Host ""
        
        # Disco
        Write-ColoredText "Disco (%):" "Cyan"
        Write-Host "  $(New-SparkLine -Data $diskData -Width 60)"
        $avgDisk = [math]::Round(($diskData | Measure-Object -Average).Average, 2)
        $maxDisk = [math]::Round(($diskData | Measure-Object -Maximum).Maximum, 2)
        Write-Host "  Promedio: $avgDisk% | Máximo: $maxDisk%"
        Write-Host ""
        
        Write-ColoredText "Snapshots registrados: $($history.Count)" "Green"
    }
    catch {
        Write-ColoredText "❌ Error al leer datos: $($_.Exception.Message)" "Red"
    }
}

function Export-DashboardHTML {
    <#
    .SYNOPSIS
        Exporta dashboard a HTML
    #>
    Write-ColoredText "`n📄 EXPORTAR DASHBOARD A HTML" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    $metrics = Get-SystemMetricsDetailed
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "$env:USERPROFILE\Desktop\Dashboard_$timestamp.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard del Sistema - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
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
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            padding: 30px;
        }
        h1 {
            color: #667eea;
            text-align: center;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .timestamp {
            text-align: center;
            color: #777;
            margin-bottom: 30px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        .card h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.5em;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #ddd;
        }
        .metric:last-child {
            border-bottom: none;
        }
        .metric-label {
            font-weight: bold;
            color: #555;
        }
        .metric-value {
            color: #667eea;
            font-weight: bold;
        }
        .progress-bar {
            width: 100%;
            height: 25px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        .progress-high { background: linear-gradient(90deg, #f093fb 0%, #f5576c 100%) !important; }
        .progress-medium { background: linear-gradient(90deg, #ffd89b 0%, #f5af19 100%) !important; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #667eea;
            color: white;
        }
        tr:hover {
            background: #f5f5f5;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #777;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖥️ Dashboard del Sistema</h1>
        <div class="timestamp">Generado el $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</div>
        
        <div class="grid">
            <div class="card">
                <h2>💻 Sistema</h2>
                <div class="metric">
                    <span class="metric-label">Sistema Operativo:</span>
                    <span class="metric-value">$($metrics.System.OS)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Versión:</span>
                    <span class="metric-value">$($metrics.System.Version)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Tiempo de actividad:</span>
                    <span class="metric-value">$($metrics.System.Uptime)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Procesos:</span>
                    <span class="metric-value">$($metrics.System.ProcessCount)</span>
                </div>
            </div>
            
            <div class="card">
                <h2>🔧 CPU</h2>
                <div class="metric">
                    <span class="metric-label">Procesador:</span>
                    <span class="metric-value">$($metrics.CPU.Name)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Núcleos / Hilos:</span>
                    <span class="metric-value">$($metrics.CPU.Cores) / $($metrics.CPU.Threads)</span>
                </div>
                <div class="metric-label">Uso:</div>
                <div class="progress-bar">
                    <div class="progress-fill $(if ($metrics.CPU.Usage -gt 80) { 'progress-high' } elseif ($metrics.CPU.Usage -gt 60) { 'progress-medium' })" style="width: $($metrics.CPU.Usage)%">
                        $($metrics.CPU.Usage)%
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h2>💾 Memoria RAM</h2>
                <div class="metric">
                    <span class="metric-label">Total:</span>
                    <span class="metric-value">$($metrics.RAM.Total) GB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">En uso:</span>
                    <span class="metric-value">$($metrics.RAM.Used) GB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Disponible:</span>
                    <span class="metric-value">$($metrics.RAM.Free) GB</span>
                </div>
                <div class="metric-label">Uso:</div>
                <div class="progress-bar">
                    <div class="progress-fill $(if ($metrics.RAM.Percent -gt 80) { 'progress-high' } elseif ($metrics.RAM.Percent -gt 60) { 'progress-medium' })" style="width: $($metrics.RAM.Percent)%">
                        $($metrics.RAM.Percent)%
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h2>💿 Disco C:</h2>
                <div class="metric">
                    <span class="metric-label">Total:</span>
                    <span class="metric-value">$($metrics.Disk.Total) GB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">En uso:</span>
                    <span class="metric-value">$($metrics.Disk.Used) GB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Disponible:</span>
                    <span class="metric-value">$($metrics.Disk.Free) GB</span>
                </div>
                <div class="metric-label">Uso:</div>
                <div class="progress-bar">
                    <div class="progress-fill $(if ($metrics.Disk.Percent -gt 80) { 'progress-high' } elseif ($metrics.Disk.Percent -gt 60) { 'progress-medium' })" style="width: $($metrics.Disk.Percent)%">
                        $($metrics.Disk.Percent)%
                    </div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>🔥 Top 5 Procesos (CPU)</h2>
            <table>
                <thead>
                    <tr>
                        <th>Proceso</th>
                        <th>Tiempo CPU (s)</th>
                        <th>RAM (MB)</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($proc in $metrics.TopProcesses.CPU) {
        $ramMB = [math]::Round($proc.WorkingSet / 1MB, 2)
        $cpuTime = [math]::Round($proc.CPU, 2)
        $html += @"
                    <tr>
                        <td>$($proc.Name)</td>
                        <td>$cpuTime</td>
                        <td>$ramMB</td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>Generado por Optimizador de Computadora v2.8.0</p>
            <p>© 2025 - Dashboard Avanzado del Sistema</p>
        </div>
    </div>
</body>
</html>
"@

    try {
        $html | Out-File -FilePath $outputPath -Encoding UTF8
        
        Write-ColoredText "✅ Dashboard exportado exitosamente" "Green"
        Write-Host "   Ubicación: $outputPath"
        Write-Host ""
        
        $openFile = Read-Host "¿Abrir archivo ahora? (S/N)"
        if ($openFile -eq "S") {
            Start-Process $outputPath
        }
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Dashboard exportado a HTML: $outputPath" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al exportar: $($_.Exception.Message)" "Red"
    }
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

do {
    Show-Header
    
    Write-Host "  📊 VISUALIZACIÓN"
    Write-Host "  ─────────────────────"
    Write-Host "  1. 📺 Dashboard en tiempo real"
    Write-Host "  2. 📈 Gráficos históricos (30 días)"
    Write-Host "  3. 📸 Guardar snapshot actual"
    Write-Host ""
    Write-Host "  📤 EXPORTACIÓN"
    Write-Host "  ─────────────────────"
    Write-Host "  4. 🌐 Exportar a HTML"
    Write-Host ""
    Write-Host "  0. ↩️  Volver al menú principal"
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción"
    
    switch ($opcion) {
        "1" {
            Show-Header
            try {
                Show-LiveDashboard
            }
            catch {
                Write-ColoredText "`n⚠ Dashboard detenido por el usuario" "Yellow"
            }
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "2" {
            Show-Header
            Show-HistoricalCharts
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "3" {
            Show-Header
            Save-DashboardSnapshot
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "4" {
            Show-Header
            Export-DashboardHTML
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "0" {
            Write-ColoredText "`n✅ Volviendo al menú principal..." "Green"
            Start-Sleep -Seconds 1
        }
        default {
            Write-ColoredText "`n❌ Opción inválida" "Red"
            Start-Sleep -Seconds 2
        }
    }
} while ($opcion -ne "0")

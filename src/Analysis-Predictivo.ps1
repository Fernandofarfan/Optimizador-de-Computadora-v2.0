# Análisis Predictivo de Rendimiento v4.0
# Predice problemas del sistema basado en métricas históricas

param(
    [switch]$Test
)

$Global:PredictorVersion = "4.0.0"

# Ruta de datos históricos
$metricsPath = "$env:USERPROFILE\OptimizadorPC\metrics\daily_metrics.json"

# --- FUNCIONES PRINCIPALES ---

function Initialize-MetricsSystem {
    <#
    .SYNOPSIS
        Inicializa el sistema de métricas
    #>
    $directory = Split-Path -Parent $metricsPath
    if (-not (Test-Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
}

function Collect-SystemMetrics {
    <#
    .SYNOPSIS
        Recolecta métricas actuales del sistema
    #>
    
    $metrics = @{
        Date = Get-Date -Format 'yyyy-MM-dd'
        Time = Get-Date -Format 'HH:mm:ss'
        Timestamp = Get-Date -UnixTimeSeconds
    }
    
    # RAM
    try {
        $ram = Get-CimInstance Win32_OperatingSystem
        $metrics.RAM = @{
            Total_GB = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
            Used_GB = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / 1MB, 2)
            Free_GB = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
            Used_Percent = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize * 100, 2)
        }
    }
    catch { $metrics.RAM = $null }
    
    # CPU
    try {
        $cpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object { $_.Name -eq "_Total" }
        $metrics.CPU = @{
            Usage_Percent = [math]::Round($cpu.PercentProcessorTime, 2)
        }
    }
    catch { $metrics.CPU = $null }
    
    # Disco
    try {
        $disk = Get-PSDrive C
        if ($disk) {
            $metrics.Disk = @{
                Total_GB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
                Used_GB = [math]::Round($disk.Used / 1GB, 2)
                Free_GB = [math]::Round($disk.Free / 1GB, 2)
                Used_Percent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 2)
            }
        }
    }
    catch { $metrics.Disk = $null }
    
    # Procesos principales
    try {
        $topProcesses = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5 @{
            Name = 'Name'
            Expression = { $_.ProcessName }
        }, @{
            Name = 'Memory_MB'
            Expression = { [math]::Round($_.WorkingSet / 1MB, 2) }
        }
        $metrics.Top_Processes = $topProcesses
    }
    catch { $metrics.Top_Processes = $null }
    
    # Uptime
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        $metrics.Uptime_Days = [math]::Round($uptime.TotalDays, 2)
    }
    catch { $metrics.Uptime_Days = $null }
    
    return $metrics
}

function Save-DailyMetrics {
    <#
    .SYNOPSIS
        Guarda métricas del día en JSON
    #>
    
    $metrics = Collect-SystemMetrics
    
    try {
        $history = @()
        if (Test-Path $metricsPath) {
            $history = Get-Content $metricsPath | ConvertFrom-Json
        }
        
        # Evitar duplicados del mismo día
        $today = (Get-Date).Date
        $history = $history | Where-Object { 
            [datetime]$_.Date -ne $today 
        }
        
        $history += $metrics
        
        # Mantener solo últimos 90 días
        if ($history.Count -gt 90) {
            $history = $history[-90..-1]
        }
        
        $history | ConvertTo-Json | Set-Content $metricsPath
        return $metrics
    }
    catch {
        Write-Host "Error al guardar métricas: $_" -ForegroundColor Red
        return $null
    }
}

function Get-MetricsHistory {
    <#
    .SYNOPSIS
        Obtiene historial de métricas
    
    .PARAMETER Days
        Número de días a recuperar
    #>
    param(
        [int]$Days = 30
    )
    
    if (-not (Test-Path $metricsPath)) {
        return @()
    }
    
    try {
        $history = Get-Content $metricsPath | ConvertFrom-Json
        return $history | Select-Object -Last $Days
    }
    catch {
        return @()
    }
}

function Predict-DiskFullness {
    <#
    .SYNOPSIS
        Predice cuándo se llenará el disco
    #>
    
    $history = Get-MetricsHistory -Days 30
    
    if ($history.Count -lt 3) {
        Write-Host "Sin datos suficientes para predicción" -ForegroundColor Yellow
        return $null
    }
    
    # Calcular tendencia de crecimiento
    $diskMetrics = $history | Where-Object { $null -ne $_.Disk } | Select-Object -ExpandProperty Disk
    
    if ($diskMetrics.Count -lt 2) {
        return $null
    }
    
    $first = $diskMetrics[0].Used_Percent
    $last = $diskMetrics[-1].Used_Percent
    
    $growth = ($last - $first) / $diskMetrics.Count  # Crecimiento diario
    
    if ($growth -le 0) {
        return @{
            Warning = $false
            Message = "Uso de disco estable o decreciente"
        }
    }
    
    $daysUntilFull = (100 - $last) / $growth
    $fullDate = (Get-Date).AddDays($daysUntilFull)
    
    return @{
        Warning = $true
        Current_Usage = $last
        Daily_Growth = [math]::Round($growth, 2)
        Days_Until_Full = [math]::Round($daysUntilFull, 1)
        Predicted_Full_Date = $fullDate.ToString('yyyy-MM-dd')
        Recommendation = if ($daysUntilFull -lt 7) { "URGENTE - Libera espacio ahora" } else { "Planifica limpieza próximamente" }
    }
}

function Predict-SystemDegradation {
    <#
    .SYNOPSIS
        Predice degradación del sistema
    #>
    
    $history = Get-MetricsHistory -Days 30
    
    if ($history.Count -lt 5) {
        return @{ Warning = $false; Message = "Sin datos históricos suficientes" }
    }
    
    $predictions = @{
        Warnings = @()
        Recommendations = @()
    }
    
    # Análisis de tendencia de RAM
    $ramMetrics = $history | Where-Object { $null -ne $_.RAM } | Select-Object -ExpandProperty RAM
    if ($ramMetrics.Count -gt 1) {
        $ramGrowth = (($ramMetrics[-1].Used_Percent - $ramMetrics[0].Used_Percent) / $ramMetrics.Count)
        
        if ($ramGrowth -gt 0.5) {
            $predictions.Warnings += "RAM: Tendencia creciente de uso (+$([math]::Round($ramGrowth, 2))% diario)"
            $predictions.Recommendations += "Considera desinstalar aplicaciones innecesarias o aumentar RAM"
        }
    }
    
    # Análisis de Uptime (inestabilidad)
    $uptimeMetrics = $history | Where-Object { $null -ne $_.Uptime_Days } | Select-Object -ExpandProperty Uptime_Days
    if ($uptimeMetrics -and $uptimeMetrics[-1] -lt 1) {
        $predictions.Warnings += "Sistema reiniciado frecuentemente (uptime < 1 día)"
        $predictions.Recommendations += "Investiga causas de reinicio: BSOD, actualizaciones, sobrecalentamiento"
    }
    
    return $predictions
}

function Get-MaintenanceSchedule {
    <#
    .SYNOPSIS
        Genera cronograma de mantenimiento recomendado
    #>
    
    $current = Collect-SystemMetrics
    $predictions = Predict-SystemDegradation
    $diskPrediction = Predict-DiskFullness
    
    $schedule = @()
    
    # Limpieza de disco
    if ($diskPrediction -and $diskPrediction.Warning) {
        $daysToAdd = if ($diskPrediction.Days_Until_Full -lt 7) { 0 } else { 3 }
        $priorityLevel = if ($diskPrediction.Days_Until_Full -lt 3) { "CRÍTICA" } else { "ALTA" }
        $schedule += @{
            Task = "Limpieza de Disco"
            Priority = $priorityLevel
            Date = (Get-Date).AddDays($daysToAdd).ToString('yyyy-MM-dd')
            Reason = $diskPrediction.Recommendation
        }
    }
    
    # Actualización de drivers
    $schedule += @{
        Task = "Actualizar Drivers"
        Priority = "NORMAL"
        Date = (Get-Date).AddDays(7).ToString('yyyy-MM-dd')
        Reason = "Mantenimiento preventivo mensual"
    }
    
    # Desfragmentación
    if ($current.Disk -and $current.Disk.Used_Percent -lt 75) {
        $schedule += @{
            Task = "Desfragmentación / TRIM"
            Priority = "NORMAL"
            Date = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
            Reason = "Optimizar rendimiento de disco"
        }
    }
    
    return $schedule
}

function Show-PredictiveReport {
    <#
    .SYNOPSIS
        Muestra reporte predictivo completo
    #>
    
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "      ANÁLISIS PREDICTIVO DE RENDIMIENTO v$Global:PredictorVersion" -ForegroundColor White
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Métricas actuales
    Write-Host "📊 ESTADO ACTUAL DEL SISTEMA" -ForegroundColor Green
    $current = Collect-SystemMetrics
    
    if ($current.RAM) {
        Write-Host "  RAM:   $($current.RAM.Used_GB)GB / $($current.RAM.Total_GB)GB ($($current.RAM.Used_Percent)%)" -ForegroundColor Cyan
    }
    if ($current.CPU) {
        Write-Host "  CPU:   $($current.CPU.Usage_Percent)%" -ForegroundColor Cyan
    }
    if ($current.Disk) {
        Write-Host "  Disco: $($current.Disk.Used_GB)GB / $($current.Disk.Total_GB)GB ($($current.Disk.Used_Percent)%)" -ForegroundColor Cyan
    }
    Write-Host "  Uptime: $($current.Uptime_Days) días" -ForegroundColor Cyan
    
    # Predicción de disco
    Write-Host "`n⚠️  PREDICCIÓN DE DISCO" -ForegroundColor Yellow
    $diskPred = Predict-DiskFullness
    if ($diskPred) {
        if ($diskPred.Warning) {
            Write-Host "  ⚠️  $($diskPred.Recommendation)" -ForegroundColor Red
            Write-Host "     Crecimiento: $($diskPred.Daily_Growth)% diario" -ForegroundColor Yellow
            Write-Host "     Disco lleno en: $($diskPred.Days_Until_Full) días ($($diskPred.Predicted_Full_Date))" -ForegroundColor Red
        }
        else {
            Write-Host "  ✓ $($diskPred.Message)" -ForegroundColor Green
        }
    }
    
    # Predicción de degradación
    Write-Host "`n🔍 ANÁLISIS DE DEGRADACIÓN" -ForegroundColor Yellow
    $degradation = Predict-SystemDegradation
    
    if ($degradation.Warnings.Count -gt 0) {
        foreach ($warning in $degradation.Warnings) {
            Write-Host "  ⚠️  $warning" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ✓ No se detectan tendencias negativas" -ForegroundColor Green
    }
    
    if ($degradation.Recommendations.Count -gt 0) {
        Write-Host "`n💡 RECOMENDACIONES:" -ForegroundColor Cyan
        foreach ($rec in $degradation.Recommendations) {
            Write-Host "  • $rec" -ForegroundColor Cyan
        }
    }
    
    # Cronograma de mantenimiento
    Write-Host "`n📅 CRONOGRAMA DE MANTENIMIENTO RECOMENDADO" -ForegroundColor Green
    $schedule = Get-MaintenanceSchedule
    
    foreach ($item in $schedule) {
        $priorityColor = switch ($item.Priority) {
            'CRÍTICA' { 'Red' }
            'ALTA' { 'Yellow' }
            default { 'Cyan' }
        }
        Write-Host "  [$($item.Date)] [$($item.Priority)]" -ForegroundColor $priorityColor
        Write-Host "    • $($item.Task)" -ForegroundColor White
        Write-Host "    • $($item.Reason)" -ForegroundColor Gray
    }
    
    Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Export-PredictionHTML {
    <#
    .SYNOPSIS
        Exporta predicción a HTML
    #>
    param(
        [string]$OutputPath = "$env:USERPROFILE\Desktop\prediction.html"
    )
    
    $current = Collect-SystemMetrics
    $diskPred = Predict-DiskFullness
    $schedule = Get-MaintenanceSchedule
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Análisis Predictivo - Optimizador PC</title>
    <style>
        body { font-family: 'Segoe UI', Arial; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 10px; padding: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
        h1 { color: #333; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
        .metric { display: inline-block; width: 23%; margin: 1%; background: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; }
        .metric-value { font-size: 24px; font-weight: bold; color: #667eea; }
        .metric-label { color: #666; font-size: 12px; margin-top: 5px; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0; border-radius: 4px; }
        .danger { background: #f8d7da; border-left: 4px solid #dc3545; padding: 10px; margin: 10px 0; border-radius: 4px; color: #721c24; }
        .success { background: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin: 10px 0; border-radius: 4px; color: #155724; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .critical { color: #dc3545; font-weight: bold; }
        .footer { text-align: center; margin-top: 20px; color: #999; font-size: 11px; }
    </style>
</head>
<body>
    <div class='container'>
        <h1>📊 Análisis Predictivo de Rendimiento</h1>
        <p>Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        
        <h2>Estado Actual</h2>
        <div class='metric'>
            <div class='metric-value'>$([math]::Round($current.RAM.Used_Percent, 0))%</div>
            <div class='metric-label'>RAM</div>
        </div>
        <div class='metric'>
            <div class='metric-value'>$([math]::Round($current.CPU.Usage_Percent, 0))%</div>
            <div class='metric-label'>CPU</div>
        </div>
        <div class='metric'>
            <div class='metric-value'>$([math]::Round($current.Disk.Used_Percent, 0))%</div>
            <div class='metric-label'>Disco</div>
        </div>
        <div class='metric'>
            <div class='metric-value'>$([math]::Round($current.Uptime_Days, 1))</div>
            <div class='metric-label'>Uptime (días)</div>
        </div>
        
        <h2>Predicciones</h2>
"@
    
    if ($diskPred -and $diskPred.Warning) {
        $html += "<div class='danger'><strong>⚠️ ALERTA DISCO:</strong> $($diskPred.Recommendation)<br/>Disco lleno en $($diskPred.Days_Until_Full) días</div>"
    }
    else {
        $html += "<div class='success'><strong>✓ Disco:</strong> Estado normal</div>"
    }
    
    $html += "<h2>Cronograma de Mantenimiento</h2><table><tr><th>Fecha</th><th>Tarea</th><th>Prioridad</th><th>Razón</th></tr>"
    
    foreach ($item in $schedule) {
        $priorityClass = if ($item.Priority -eq 'CRÍTICA') { 'critical' } else { '' }
        $html += "<tr><td>$($item.Date)</td><td>$($item.Task)</td><td class='$priorityClass'>$($item.Priority)</td><td>$($item.Reason)</td></tr>"
    }
    
    $html += "</table><div class='footer'><p>Optimizador de Computadora v$Global:PredictorVersion</p></div></div></body></html>"
    
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    Write-Host "✓ Reporte exportado a: $OutputPath" -ForegroundColor Green
}

# --- EJECUCIÓN ---

if ($Test) {
    Write-Host "▶ Modo Test" -ForegroundColor Yellow
    Initialize-MetricsSystem
    Save-DailyMetrics
    Show-PredictiveReport
}
else {
    Initialize-MetricsSystem
    Show-PredictiveReport
    Read-Host "`nPresiona Enter"
}

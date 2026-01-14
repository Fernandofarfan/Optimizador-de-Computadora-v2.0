# Notificaciones Inteligentes del Sistema v4.0
# Sistema de alertas proactivo para estado crítico del sistema

param(
    [switch]$Test
)

# --- CONFIGURACIÓN GLOBAL ---
$Global:SmartNotificationsVersion = "4.0.0"
$Global:AlertThresholds = @{
    RAM = 95          # Porcentaje crítico
    Disco = 95        # Porcentaje crítico
    CPU = 90          # Porcentaje sostenido
    Temperatura = 85  # Grados Celsius
}

# Ruta de historial de alertas
$alertHistoryPath = "$env:USERPROFILE\OptimizadorPC\alerts\alert_history.json"

# --- FUNCIONES PRINCIPALES ---

function Initialize-AlertSystem {
    <#
    .SYNOPSIS
        Inicializa el sistema de alertas
    #>
    $directory = Split-Path -Parent $alertHistoryPath
    if (-not (Test-Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
}

function Show-CriticalAlert {
    <#
    .SYNOPSIS
        Muestra alerta crítica en Windows Notification Center
    
    .PARAMETER Title
        Título de la alerta
    
    .PARAMETER Message
        Mensaje de la alerta
    
    .PARAMETER Severity
        Severidad: CRITICAL, WARNING, INFO
    #>
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet('CRITICAL', 'WARNING', 'INFO')][string]$Severity = 'WARNING'
    )
    
    try {
        # Usar PowerShell Toast Notification
        $xml = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$Title</text>
            <text id="2">$Message</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" silent="false" />
</toast>
"@
        
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        $APP_ID = 'Optimizador.PC.Monitor'
        
        $xml_doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml_doc.LoadXml($xml)
        
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml_doc
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($APP_ID).Show($toast)
        
        Log-Alert -Title $Title -Message $Message -Severity $Severity
        return $true
    }
    catch {
        # Fallback a Write-Host
        $color = if ($Severity -eq 'CRITICAL') { 'Red' } elseif ($Severity -eq 'WARNING') { 'Yellow' } else { 'Cyan' }
        Write-Host "`n[$Severity] $Title" -ForegroundColor $color
        Write-Host "  $Message" -ForegroundColor $color
        return $false
    }
}

function Monitor-SystemResources {
    <#
    .SYNOPSIS
        Monitorea recursos del sistema y emite alertas si es necesario
    #>
    
    # Verificar RAM
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramUsagePercent = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize * 100)
    
    if ($ramUsagePercent -gt $Global:AlertThresholds.RAM) {
        Show-CriticalAlert -Title "ALERTA: RAM CRÍTICA" `
            -Message "Uso de memoria: $ramUsagePercent% - Cierra aplicaciones innecesarias" `
            -Severity "CRITICAL"
    }
    
    # Verificar Disco C:
    $disk = Get-PSDrive C
    if ($disk) {
        $diskUsagePercent = [math]::Round(($disk.Used / $disk.Used + $disk.Free) * 100)
        
        if ($diskUsagePercent -gt $Global:AlertThresholds.Disco) {
            Show-CriticalAlert -Title "ALERTA: DISCO CASI LLENO" `
                -Message "Unidad C: $diskUsagePercent% ocupado - Libera espacio urgentemente" `
                -Severity "CRITICAL"
        }
    }
    
    # Verificar CPU (promedio de últimos 5 segundos)
    try {
        $cpuSamples = @()
        1..5 | ForEach-Object {
            $cpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object { $_.Name -eq "_Total" }
            $cpuSamples += $cpu.PercentProcessorTime
            Start-Sleep -Milliseconds 200
        }
        
        $avgCpu = [math]::Round(($cpuSamples | Measure-Object -Average).Average)
        
        if ($avgCpu -gt $Global:AlertThresholds.CPU) {
            Show-CriticalAlert -Title "ALERTA: CPU AL MÁXIMO" `
                -Message "Uso de CPU: $avgCpu% - Hay procesos consumiendo recursos" `
                -Severity "WARNING"
        }
    }
    catch {
        # CPU monitoring puede fallar en algunos sistemas
    }
}

function Log-Alert {
    <#
    .SYNOPSIS
        Registra alerta en el historial
    #>
    param(
        [string]$Title,
        [string]$Message,
        [string]$Severity = 'INFO'
    )
    
    $alert = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Title = $Title
        Message = $Message
        Severity = $Severity
        Computer = $env:COMPUTERNAME
        User = $env:USERNAME
    }
    
    try {
        $history = @()
        if (Test-Path $alertHistoryPath) {
            $history = Get-Content $alertHistoryPath | ConvertFrom-Json
        }
        
        $history += $alert
        
        # Mantener solo últimas 1000 alertas
        if ($history.Count -gt 1000) {
            $history = $history[-1000..-1]
        }
        
        $history | ConvertTo-Json | Set-Content $alertHistoryPath
    }
    catch {
        # No fallar si no se puede guardar historial
    }
}

function Get-AlertHistory {
    <#
    .SYNOPSIS
        Obtiene el historial de alertas
    
    .PARAMETER Last
        Número de últimas alertas a obtener
    
    .PARAMETER Filter
        Filtro por severidad (CRITICAL, WARNING, INFO)
    #>
    param(
        [int]$Last = 50,
        [ValidateSet('CRITICAL', 'WARNING', 'INFO', 'ALL')][string]$Filter = 'ALL'
    )
    
    if (-not (Test-Path $alertHistoryPath)) {
        Write-Host "No hay historial de alertas" -ForegroundColor Yellow
        return @()
    }
    
    try {
        $history = Get-Content $alertHistoryPath | ConvertFrom-Json
        
        if ($Filter -ne 'ALL') {
            $history = $history | Where-Object { $_.Severity -eq $Filter }
        }
        
        return ($history | Select-Object -Last $Last)
    }
    catch {
        Write-Host "Error al leer historial: $_" -ForegroundColor Red
        return @()
    }
}

function Show-AlertHistory {
    <#
    .SYNOPSIS
        Muestra historial formateado
    #>
    param(
        [int]$Last = 20,
        [ValidateSet('CRITICAL', 'WARNING', 'INFO', 'ALL')][string]$Filter = 'ALL'
    )
    
    $alerts = Get-AlertHistory -Last $Last -Filter $Filter
    
    if ($alerts.Count -eq 0) {
        Write-Host "Sin alertas" -ForegroundColor Green
        return
    }
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              HISTORIAL DE ALERTAS DEL SISTEMA                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    foreach ($alert in $alerts) {
        $color = switch ($alert.Severity) {
            'CRITICAL' { 'Red' }
            'WARNING' { 'Yellow' }
            default { 'Cyan' }
        }
        
        Write-Host "`n[$($alert.Timestamp)] [$($alert.Severity)]" -ForegroundColor $color
        Write-Host "  Título: $($alert.Title)"
        Write-Host "  Mensaje: $($alert.Message)"
        Write-Host "  Usuario: $($alert.User)@$($alert.Computer)"
    }
    
    Write-Host ""
}

function Start-ContinuousMonitoring {
    <#
    .SYNOPSIS
        Inicia monitoreo continuo del sistema
    
    .PARAMETER IntervalSeconds
        Intervalo de chequeo en segundos
    
    .PARAMETER Duration
        Duración total en segundos (0 = indefinido)
    #>
    param(
        [int]$IntervalSeconds = 30,
        [int]$Duration = 0
    )
    
    Initialize-AlertSystem
    
    Write-Host "▶ Iniciando monitoreo continuo del sistema..." -ForegroundColor Green
    Write-Host "  Intervalo de chequeo: ${IntervalSeconds}s" -ForegroundColor Gray
    Write-Host "  Presiona Ctrl+C para detener" -ForegroundColor Gray
    
    $startTime = Get-Date
    $checkCount = 0
    
    try {
        while ($true) {
            $checkCount++
            Write-Host "  [$checkCount] Chequeo a las $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
            
            Monitor-SystemResources
            
            if ($Duration -gt 0) {
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -ge $Duration) {
                    break
                }
            }
            
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    finally {
        Write-Host "`n✓ Monitoreo detenido" -ForegroundColor Green
    }
}

function Export-AlertHistoryHTML {
    <#
    .SYNOPSIS
        Exporta historial de alertas a HTML
    
    .PARAMETER OutputPath
        Ruta de salida del archivo HTML
    #>
    param(
        [string]$OutputPath = "$env:USERPROFILE\Desktop\alertas.html"
    )
    
    $alerts = Get-AlertHistory -Last 100 -Filter 'ALL'
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Historial de Alertas del Sistema</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 20px; }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        th { background: #007bff; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .CRITICAL { color: #d9534f; font-weight: bold; }
        .WARNING { color: #f0ad4e; font-weight: bold; }
        .INFO { color: #5bc0de; }
        .footer { margin-top: 20px; text-align: center; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <h1>📊 Historial de Alertas del Sistema</h1>
    <p>Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <table>
        <tr>
            <th>Fecha/Hora</th>
            <th>Severidad</th>
            <th>Título</th>
            <th>Mensaje</th>
            <th>Usuario</th>
        </tr>
"@
    
    foreach ($alert in $alerts) {
        $html += "<tr>`n"
        $html += "<td>$($alert.Timestamp)</td>`n"
        $html += "<td class='$($alert.Severity)'>$($alert.Severity)</td>`n"
        $html += "<td>$($alert.Title)</td>`n"
        $html += "<td>$($alert.Message)</td>`n"
        $html += "<td>$($alert.User)</td>`n"
        $html += "</tr>`n"
    }
    
    $html += @"
    </table>
    <div class='footer'>
        <p>Optimizador de Computadora v$Global:SmartNotificationsVersion</p>
        <p>Total de alertas: $($alerts.Count)</p>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    Write-Host "✓ Historial exportado a: $OutputPath" -ForegroundColor Green
}

# --- MENU PRINCIPAL ---

function Show-Menu {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "    SISTEMA DE NOTIFICACIONES INTELIGENTES v$Global:SmartNotificationsVersion" -ForegroundColor White
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Monitoreo Continuo (30 segundos)" -ForegroundColor Green
    Write-Host "  [2] Chequeo Manual Inmediato" -ForegroundColor Green
    Write-Host "  [3] Ver Historial de Alertas" -ForegroundColor Cyan
    Write-Host "  [4] Exportar Historial a HTML" -ForegroundColor Cyan
    Write-Host "  [5] Configurar Umbrales" -ForegroundColor Yellow
    Write-Host "  [0] Salir" -ForegroundColor Gray
    Write-Host ""
}

# --- EJECUCIÓN PRINCIPAL ---

if ($Test) {
    Write-Host "▶ Modo Test activado" -ForegroundColor Yellow
    Initialize-AlertSystem
    Monitor-SystemResources
    Show-AlertHistory
    export-alertHistoryHTML "$env:TEMP\test_alerts.html"
}
else {
    while ($true) {
        Show-Menu
        $choice = Read-Host "  Selecciona opción"
        
        switch ($choice) {
            '1' { Start-ContinuousMonitoring -IntervalSeconds 30 }
            '2' { 
                Initialize-AlertSystem
                Monitor-SystemResources
                Write-Host "`n✓ Chequeo completado" -ForegroundColor Green
                Read-Host "Presiona Enter para continuar"
            }
            '3' { Show-AlertHistory -Last 50 -Filter 'ALL' ; Read-Host "Presiona Enter" }
            '4' { Export-AlertHistoryHTML ; Read-Host "Presiona Enter" }
            '5' { 
                Write-Host "`nUmbrales actuales:" -ForegroundColor Cyan
                $Global:AlertThresholds.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)%" }
                Read-Host "Presiona Enter"
            }
            '0' { break }
            default { Write-Host "Opción inválida" -ForegroundColor Red }
        }
    }
}

# Notificaciones Inteligentes del Sistema v4.0.0
# Sistema de alertas proactivo para estado critico del sistema

param(
    [switch]$Test
)

# --- CONFIGURACION GLOBAL ---
$Global:SmartNotificationsVersion = "4.0.0"
$Global:AlertThresholds = @{
    RAM = 95          # Porcentaje critico
    Disco = 95        # Porcentaje critico
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
        Muestra alerta critica en Windows Notification Center
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
    # Verificar RAM
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramUsagePercent = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize * 100)
    
    if ($ramUsagePercent -gt $Global:AlertThresholds.RAM) {
        Show-CriticalAlert -Title "ALERTA: RAM CRITICA" `
            -Message "Uso de memoria: $ramUsagePercent% - Cierra aplicaciones innecesarias" `
            -Severity "CRITICAL"
    }
    
    # Verificar Disco C:
    $psDrive = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($psDrive) {
        $diskUsagePercent = [math]::Round(($psDrive.Used / ($psDrive.Used + $psDrive.Free)) * 100)
        
        if ($diskUsagePercent -gt $Global:AlertThresholds.Disco) {
            Show-CriticalAlert -Title "ALERTA: DISCO CASI LLENO" `
                -Message "Unidad C: $diskUsagePercent% ocupado - Libera espacio urgentemente" `
                -Severity "CRITICAL"
        }
    }
}

function Log-Alert {
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
        if ($history.Count -gt 1000) { $history = $history[-1000..-1] }
        $history | ConvertTo-Json | Set-Content $alertHistoryPath
    } catch {}
}

function Get-AlertHistory {
    param(
        [int]$Last = 50,
        [ValidateSet('CRITICAL', 'WARNING', 'INFO', 'ALL')][string]$Filter = 'ALL'
    )
    
    if (-not (Test-Path $alertHistoryPath)) { return @() }
    
    try {
        $history = Get-Content $alertHistoryPath | ConvertFrom-Json
        if ($Filter -ne 'ALL') { $history = $history | Where-Object { $_.Severity -eq $Filter } }
        return ($history | Select-Object -Last $Last)
    } catch { return @() }
}

function Show-AlertHistory {
    param([int]$Last = 20, [string]$Filter = 'ALL')
    $alerts = Get-AlertHistory -Last $Last -Filter $Filter
    if ($alerts.Count -eq 0) { Write-Host "Sin alertas" -ForegroundColor Green ; return }
    
    Write-Host "`n+----------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|              HISTORIAL DE ALERTAS DEL SISTEMA                  |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------------------------+" -ForegroundColor Cyan
    
    foreach ($alert in $alerts) {
        $color = if ($alert.Severity -eq 'CRITICAL') { 'Red' } elseif ($alert.Severity -eq 'WARNING') { 'Yellow' } else { 'Cyan' }
        Write-Host "`n[$($alert.Timestamp)] [$($alert.Severity)]" -ForegroundColor $color
        Write-Host "  Titulo: $($alert.Title)"
        Write-Host "  Mensaje: $($alert.Message)"
    }
}

function Start-ContinuousMonitoring {
    param([int]$IntervalSeconds = 30, [int]$Duration = 0)
    Initialize-AlertSystem
    Write-Host "[START] Iniciando monitoreo continuo..." -ForegroundColor Green
    $startTime = Get-Date
    try {
        while ($true) {
            Monitor-SystemResources
            if ($Duration -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -ge $Duration) { break }
            Start-Sleep -Seconds $IntervalSeconds
        }
    } finally { Write-Host "[STOP] Monitoreo detenido" -ForegroundColor Green }
}

# Exportar funciones (solo si se carga como modulo)
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function Initialize-AlertSystem, Show-CriticalAlert, Monitor-SystemResources, `
                                  Log-Alert, Get-AlertHistory, Show-AlertHistory, Start-ContinuousMonitoring
}

if ($Test) {
    Initialize-AlertSystem
    Monitor-SystemResources
    Show-AlertHistory
}

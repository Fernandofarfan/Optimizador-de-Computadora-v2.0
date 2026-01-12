<#
.SYNOPSIS
    Centro de Seguridad y Privacidad Avanzado para Windows
.DESCRIPTION
    Gestión completa de privacidad: permisos de aplicaciones, telemetría,
    historial de actividad, conexiones de red y generación de reportes.
.NOTES
    Versión: 2.9.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11, Permisos de Administrador
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:PrivacyReportPath = "$env:USERPROFILE\OptimizadorPC-PrivacyReport.json"
$Global:PrivacyScriptVersion = "4.0.0"

# Importar Logger si existe
if (Test-Path ".\Logger.ps1") {
    . ".\Logger.ps1"
    $Global:UseLogger = $true
} else {
    $Global:UseLogger = $false
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                              ║" -ForegroundColor Cyan
    Write-Host "  ║        🔐 CENTRO DE PRIVACIDAD Y SEGURIDAD AVANZADO         ║" -ForegroundColor White
    Write-Host "  ║                      Versión $Global:PrivacyScriptVersion                      ║" -ForegroundColor Cyan
    Write-Host "  ║                                                              ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-AppPermissions {
    <#
    .SYNOPSIS
        Analiza permisos de aplicaciones UWP (cámara, micrófono, ubicación)
    #>
    Write-Host "`n[*] Analizando permisos de aplicaciones..." -ForegroundColor Cyan
    Write-Log "Analizando permisos de aplicaciones UWP" "INFO"
    
    $permissions = @{
        Camera = @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
            Apps = @()
        }
        Microphone = @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
            Apps = @()
        }
        Location = @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
            Apps = @()
        }
        Contacts = @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts"
            Apps = @()
        }
        Calendar = @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments"
            Apps = @()
        }
    }
    
    foreach ($permission in $permissions.Keys) {
        $path = $permissions[$permission].Path
        
        if (Test-Path $path) {
            $value = Get-ItemProperty -Path $path -Name "Value" -ErrorAction SilentlyContinue
            $globalStatus = if ($value.Value -eq "Allow") { "PERMITIDO" } elseif ($value.Value -eq "Deny") { "DENEGADO" } else { "PREGUNTAR" }
            
            Write-Host "  [+] $permission`: " -NoNewline -ForegroundColor Yellow
            Write-Host $globalStatus -ForegroundColor $(if ($globalStatus -eq "PERMITIDO") { "Red" } elseif ($globalStatus -eq "DENEGADO") { "Green" } else { "Cyan" })
            
            # Listar aplicaciones con permisos específicos
            $apps = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
            
            foreach ($app in $apps) {
                $appValue = Get-ItemProperty -Path $app.PSPath -Name "Value" -ErrorAction SilentlyContinue
                if ($appValue) {
                    $appName = $app.PSChildName
                    $appStatus = if ($appValue.Value -eq "Allow") { "Permitido" } else { "Denegado" }
                    
                    $permissions[$permission].Apps += @{
                        Name = $appName
                        Status = $appStatus
                        Path = $app.PSPath
                    }
                    
                    Write-Host "      - $appName`: $appStatus" -ForegroundColor Gray
                }
            }
        }
    }
    
    return $permissions
}

function Set-AppPermission {
    <#
    .SYNOPSIS
        Configura permisos de aplicaciones
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Camera", "Microphone", "Location", "Contacts", "Calendar")]
        [string]$Permission,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Allow", "Deny")]
        [string]$Action
    )
    
    $paths = @{
        Camera = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
        Microphone = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
        Location = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        Contacts = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts"
        Calendar = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments"
    }
    
    $path = $paths[$Permission]
    
    try {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        
        Set-ItemProperty -Path $path -Name "Value" -Value $Action -ErrorAction Stop
        Write-Host "  [✓] $Permission configurado como: $Action" -ForegroundColor Green
        Write-Log "Permiso $Permission configurado como $Action" "SUCCESS"
        return $true
    }
    catch {
        Write-Host "  [✗] Error al configurar $Permission`: $_" -ForegroundColor Red
        Write-Log "Error al configurar permiso $Permission`: $_" "ERROR"
        return $false
    }
}

function Disable-TelemetryAdvanced {
    <#
    .SYNOPSIS
        Desactiva telemetría avanzada de Windows (30+ configuraciones)
    #>
    Write-Host "`n[*] Desactivando telemetría avanzada..." -ForegroundColor Cyan
    Write-Log "Iniciando desactivación de telemetría avanzada" "INFO"
    
    $telemetryKeys = @(
        # Telemetría básica
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" }
        
        # Experiencias personalizadas
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Value = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338393Enabled"; Value = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Value = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Value = 0; Type = "DWord" }
        
        # Sugerencias de Windows
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Value = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SoftLandingEnabled"; Value = 0; Type = "DWord" }
        
        # Cortana y búsqueda
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0; Type = "DWord" }
        
        # Timeline y actividad
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "UploadUserActivities"; Value = 0; Type = "DWord" }
        
        # Anuncios y sincronización
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1; Type = "DWord" }
        
        # Feedback y diagnósticos
        @{ Path = "HKCU:\Software\Microsoft\Siuf\Rules"; Name = "NumberOfSIUFInPeriod"; Value = 0; Type = "DWord" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack"; Name = "ShowedToastAtLevel"; Value = 1; Type = "DWord" }
        
        # Ubicación
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Name = "Value"; Value = "Deny"; Type = "String" }
        
        # Windows Error Reporting
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1; Type = "DWord" }
        
        # App diagnostics
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2297E4E2-5DBE-466D-A12B-0F8286F0D9CA}"; Name = "Value"; Value = "Deny"; Type = "String" }
        
        # Handwriting data
        @{ Path = "HKCU:\Software\Microsoft\InputPersonalization"; Name = "RestrictImplicitInkCollection"; Value = 1; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\InputPersonalization"; Name = "RestrictImplicitTextCollection"; Value = 1; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy"; Value = 0; Type = "DWord" }
        
        # Experiencias compartidas
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP"; Name = "RomeSdkChannelUserAuthzPolicy"; Value = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP"; Name = "CdpSessionUserAuthzPolicy"; Value = 0; Type = "DWord" }
    )
    
    $successCount = 0
    $totalCount = $telemetryKeys.Count
    
    foreach ($key in $telemetryKeys) {
        try {
            if (-not (Test-Path $key.Path)) {
                New-Item -Path $key.Path -Force | Out-Null
            }
            
            Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type $key.Type -ErrorAction Stop
            $successCount++
        }
        catch {
            Write-Log "Error al configurar $($key.Path)\$($key.Name): $_" "WARNING"
        }
    }
    
    Write-Host "  [✓] Configuradas $successCount de $totalCount claves de telemetría" -ForegroundColor Green
    Write-Log "Telemetría: $successCount/$totalCount claves configuradas" "SUCCESS"
    
    # Desactivar servicios de telemetría
    $telemetryServices = @("DiagTrack", "dmwappushservice")
    
    foreach ($service in $telemetryServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                Write-Host "  [✓] Servicio $service deshabilitado" -ForegroundColor Green
            }
        }
        catch {
            Write-Log "Error al deshabilitar servicio $service`: $_" "WARNING"
        }
    }
    
    return @{
        TotalKeys = $totalCount
        ConfiguredKeys = $successCount
        Success = ($successCount -eq $totalCount)
    }
}

function Clear-ActivityHistory {
    <#
    .SYNOPSIS
        Limpia historial de actividad y timeline de Windows
    #>
    Write-Host "`n[*] Limpiando historial de actividad..." -ForegroundColor Cyan
    Write-Log "Iniciando limpieza de historial de actividad" "INFO"
    
    $activityPath = "$env:LOCALAPPDATA\ConnectedDevicesPlatform"
    $deletedItems = 0
    
    if (Test-Path $activityPath) {
        try {
            # Detener servicio CDPUserSvc temporalmente
            $cdpServices = Get-Service -Name "CDPUserSvc*" -ErrorAction SilentlyContinue
            foreach ($svc in $cdpServices) {
                if ($svc.Status -eq "Running") {
                    Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Eliminar archivos de actividad
            $files = Get-ChildItem -Path $activityPath -Recurse -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $deletedItems++
                }
                catch {
                    Write-Log "No se pudo eliminar: $($file.FullName)" "WARNING"
                }
            }
            
            Write-Host "  [✓] Eliminados $deletedItems archivos de actividad" -ForegroundColor Green
            Write-Log "Eliminados $deletedItems archivos de historial de actividad" "SUCCESS"
        }
        catch {
            Write-Host "  [✗] Error al limpiar historial: $_" -ForegroundColor Red
            Write-Log "Error al limpiar historial de actividad: $_" "ERROR"
        }
    }
    else {
        Write-Host "  [i] No se encontró carpeta de actividad" -ForegroundColor Yellow
    }
    
    # Limpiar base de datos de Timeline
    $timelineDBPath = "$env:LOCALAPPDATA\ConnectedDevicesPlatform\*\ActivitiesCache.db"
    $timelineDBs = Get-Item -Path $timelineDBPath -ErrorAction SilentlyContinue
    
    foreach ($db in $timelineDBs) {
        try {
            Remove-Item -Path $db.FullName -Force -ErrorAction Stop
            Write-Host "  [✓] Base de datos Timeline eliminada" -ForegroundColor Green
        }
        catch {
            Write-Log "No se pudo eliminar Timeline DB: $_" "WARNING"
        }
    }
    
    return $deletedItems
}

function Get-ActiveConnections {
    <#
    .SYNOPSIS
        Analiza conexiones de red activas y detecta conexiones sospechosas
    #>
    Write-Host "`n[*] Analizando conexiones de red activas..." -ForegroundColor Cyan
    Write-Log "Analizando conexiones de red activas" "INFO"
    
    $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | 
        Select-Object -First 50 LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
    
    $connectionsInfo = @()
    $suspiciousCount = 0
    
    foreach ($conn in $connections) {
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "Desconocido" }
            
            # Determinar si es sospechosa (conexiones a IPs no comunes)
            $isSuspicious = $false
            $remoteIP = $conn.RemoteAddress
            
            # Verificar si es IP privada o conocida
            if ($remoteIP -notmatch '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)') {
                # IP pública - verificar servicios conocidos
                $knownServices = @("svchost", "chrome", "firefox", "msedge", "Teams", "OneDrive", "Dropbox")
                if ($processName -notin $knownServices) {
                    $isSuspicious = $true
                    $suspiciousCount++
                }
            }
            
            $connInfo = @{
                LocalPort = $conn.LocalPort
                RemoteAddress = $remoteIP
                RemotePort = $conn.RemotePort
                ProcessName = $processName
                ProcessId = $conn.OwningProcess
                IsSuspicious = $isSuspicious
            }
            
            $connectionsInfo += $connInfo
            
            $color = if ($isSuspicious) { "Red" } else { "Green" }
            $flag = if ($isSuspicious) { "[!]" } else { "[✓]" }
            
            Write-Host "  $flag $processName`: $remoteIP`:$($conn.RemotePort)" -ForegroundColor $color
        }
        catch {
            Write-Log "Error al procesar conexión: $_" "WARNING"
        }
    }
    
    if ($suspiciousCount -gt 0) {
        Write-Host "`n  [!] Se detectaron $suspiciousCount conexiones potencialmente sospechosas" -ForegroundColor Yellow
        Write-Log "Detectadas $suspiciousCount conexiones sospechosas" "WARNING"
    }
    else {
        Write-Host "`n  [✓] No se detectaron conexiones sospechosas" -ForegroundColor Green
    }
    
    return @{
        TotalConnections = $connections.Count
        SuspiciousConnections = $suspiciousCount
        Connections = $connectionsInfo
    }
}

function Export-PrivacyReport {
    <#
    .SYNOPSIS
        Exporta reporte completo de privacidad en JSON y HTML
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$AppPermissions,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$TelemetryResult,
        
        [Parameter(Mandatory=$true)]
        [int]$ActivityItemsDeleted,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ConnectionsData
    )
    
    Write-Host "`n[*] Generando reporte de privacidad..." -ForegroundColor Cyan
    
    $report = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ComputerName = $env:COMPUTERNAME
        Username = $env:USERNAME
        ScriptVersion = $Global:PrivacyScriptVersion
        AppPermissions = $AppPermissions
        Telemetry = $TelemetryResult
        ActivityHistory = @{
            ItemsDeleted = $ActivityItemsDeleted
        }
        NetworkConnections = $ConnectionsData
        PrivacyScore = 0
    }
    
    # Calcular puntuación de privacidad (0-100)
    $score = 100
    
    # Penalizar por permisos permitidos
    foreach ($permission in $AppPermissions.Keys) {
        $allowedApps = ($AppPermissions[$permission].Apps | Where-Object { $_.Status -eq "Permitido" }).Count
        $score -= ($allowedApps * 2)
    }
    
    # Penalizar por telemetría no configurada
    if ($TelemetryResult.Success -eq $false) {
        $score -= 20
    }
    
    # Penalizar por conexiones sospechosas
    $score -= ($ConnectionsData.SuspiciousConnections * 5)
    
    $report.PrivacyScore = [Math]::Max(0, $score)
    
    # Guardar JSON
    try {
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:PrivacyReportPath -Encoding UTF8
        Write-Host "  [✓] Reporte JSON guardado: $Global:PrivacyReportPath" -ForegroundColor Green
        Write-Log "Reporte de privacidad guardado en JSON" "SUCCESS"
    }
    catch {
        Write-Host "  [✗] Error al guardar reporte JSON: $_" -ForegroundColor Red
        Write-Log "Error al guardar reporte JSON: $_" "ERROR"
    }
    
    # Generar HTML
    $htmlPath = "$env:USERPROFILE\Desktop\PrivacyReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Privacidad - $($report.ComputerName)</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 10px 40px rgba(0,0,0,0.3); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 1.1em; }
        .score-section { text-align: center; padding: 40px; background: #f8f9fa; }
        .score-circle { width: 200px; height: 200px; margin: 0 auto; border-radius: 50%; border: 15px solid; display: flex; align-items: center; justify-content: center; font-size: 3em; font-weight: bold; }
        .score-high { border-color: #28a745; color: #28a745; }
        .score-medium { border-color: #ffc107; color: #ffc107; }
        .score-low { border-color: #dc3545; color: #dc3545; }
        .content { padding: 30px; }
        .section { margin-bottom: 30px; }
        .section h2 { color: #667eea; border-bottom: 3px solid #667eea; padding-bottom: 10px; margin-bottom: 20px; }
        .metric { display: flex; justify-content: space-between; padding: 15px; margin: 10px 0; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #667eea; }
        .metric .label { font-weight: 600; color: #333; }
        .metric .value { color: #666; }
        .alert { padding: 15px; margin: 10px 0; border-radius: 8px; border-left: 4px solid; }
        .alert-success { background: #d4edda; border-color: #28a745; color: #155724; }
        .alert-warning { background: #fff3cd; border-color: #ffc107; color: #856404; }
        .alert-danger { background: #f8d7da; border-color: #dc3545; color: #721c24; }
        .connections-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        .connections-table th { background: #667eea; color: white; padding: 12px; text-align: left; }
        .connections-table td { padding: 10px; border-bottom: 1px solid #ddd; }
        .connections-table tr:hover { background: #f8f9fa; }
        .footer { text-align: center; padding: 20px; background: #f8f9fa; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Reporte de Privacidad</h1>
            <p>$($report.ComputerName) - $($report.Username) - $($report.Timestamp)</p>
        </div>
        
        <div class="score-section">
            <h2 style="margin-bottom: 20px; color: #333;">Puntuación de Privacidad</h2>
            <div class="score-circle $(if($report.PrivacyScore -ge 80){'score-high'}elseif($report.PrivacyScore -ge 50){'score-medium'}else{'score-low'})">
                $($report.PrivacyScore)
            </div>
            <p style="margin-top: 15px; color: #666;">$(if($report.PrivacyScore -ge 80){'Excelente privacidad'}elseif($report.PrivacyScore -ge 50){'Privacidad moderada'}else{'Privacidad comprometida'})</p>
        </div>
        
        <div class="content">
            <div class="section">
                <h2>📱 Permisos de Aplicaciones</h2>
"@

    foreach ($permission in $AppPermissions.Keys) {
        $allowedCount = ($AppPermissions[$permission].Apps | Where-Object { $_.Status -eq "Permitido" }).Count
        $deniedCount = ($AppPermissions[$permission].Apps | Where-Object { $_.Status -ne "Permitido" }).Count
        
        $html += @"
                <div class="metric">
                    <span class="label">$permission</span>
                    <span class="value">$allowedCount permitidas, $deniedCount denegadas</span>
                </div>
"@
    }
    
    $html += @"
            </div>
            
            <div class="section">
                <h2>📊 Telemetría de Windows</h2>
                <div class="alert $(if($TelemetryResult.Success){'alert-success'}else{'alert-warning'})">
                    <strong>Estado:</strong> Configuradas $($TelemetryResult.ConfiguredKeys) de $($TelemetryResult.TotalKeys) claves de telemetría
                </div>
            </div>
            
            <div class="section">
                <h2>🗑️ Historial de Actividad</h2>
                <div class="metric">
                    <span class="label">Elementos eliminados</span>
                    <span class="value">$($report.ActivityHistory.ItemsDeleted) archivos</span>
                </div>
            </div>
            
            <div class="section">
                <h2>🌐 Conexiones de Red</h2>
                <div class="alert $(if($ConnectionsData.SuspiciousConnections -eq 0){'alert-success'}else{'alert-danger'})">
                    <strong>Total:</strong> $($ConnectionsData.TotalConnections) conexiones activas<br>
                    <strong>Sospechosas:</strong> $($ConnectionsData.SuspiciousConnections)
                </div>
"@

    if ($ConnectionsData.Connections.Count -gt 0) {
        $html += @"
                <table class="connections-table">
                    <thead>
                        <tr>
                            <th>Proceso</th>
                            <th>IP Remota</th>
                            <th>Puerto</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
"@
        
        foreach ($conn in ($ConnectionsData.Connections | Select-Object -First 20)) {
            $statusText = if ($conn.IsSuspicious) { "⚠️ Sospechosa" } else { "✓ Normal" }
            $html += @"
                        <tr>
                            <td>$($conn.ProcessName)</td>
                            <td>$($conn.RemoteAddress)</td>
                            <td>$($conn.RemotePort)</td>
                            <td>$statusText</td>
                        </tr>
"@
        }
        
        $html += @"
                    </tbody>
                </table>
"@
    }
    
    $html += @"
            </div>
        </div>
        
        <div class="footer">
            Generado por Optimizador de PC v$($Global:PrivacyScriptVersion) | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        </div>
    </div>
</body>
</html>
"@

    try {
        $html | Out-File -FilePath $htmlPath -Encoding UTF8
        Write-Host "  [✓] Reporte HTML guardado: $htmlPath" -ForegroundColor Green
        Write-Log "Reporte HTML guardado en: $htmlPath" "SUCCESS"
        
        # Abrir en navegador
        Start-Process $htmlPath
    }
    catch {
        Write-Host "  [✗] Error al guardar reporte HTML: $_" -ForegroundColor Red
        Write-Log "Error al guardar reporte HTML: $_" "ERROR"
    }
    
    return @{
        JsonPath = $Global:PrivacyReportPath
        HtmlPath = $htmlPath
        PrivacyScore = $report.PrivacyScore
    }
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 📱 Analizar Permisos de Aplicaciones      ║" -ForegroundColor Cyan
        Write-Host "  ║  [2] 🔐 Denegar TODOS los Permisos (Máximo)    ║" -ForegroundColor Yellow
        Write-Host "  ║  [3] 🔧 Configurar Permiso Individual          ║" -ForegroundColor Green
        Write-Host "  ║  [4] 📡 Desactivar Telemetría Avanzada         ║" -ForegroundColor Magenta
        Write-Host "  ║  [5] 🗑️  Limpiar Historial de Actividad        ║" -ForegroundColor Red
        Write-Host "  ║  [6] 🌐 Analizar Conexiones de Red             ║" -ForegroundColor Blue
        Write-Host "  ║  [7] 📄 Generar Reporte Completo               ║" -ForegroundColor White
        Write-Host "  ║  [8] 🔒 MODO MÁXIMA PRIVACIDAD (Todo)          ║" -ForegroundColor Red
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                Get-AppPermissions | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '2' {
                Write-Host "`n[!] ATENCIÓN: Se denegarán TODOS los permisos de aplicaciones" -ForegroundColor Yellow
                $confirm = Read-Host "¿Confirmar? (S/N)"
                
                if ($confirm -eq 'S' -or $confirm -eq 's') {
                    foreach ($permission in @("Camera", "Microphone", "Location", "Contacts", "Calendar")) {
                        Set-AppPermission -Permission $permission -Action "Deny"
                    }
                    Write-Host "`n[✓] Todos los permisos han sido denegados" -ForegroundColor Green
                }
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                Write-Host "`n  Permisos disponibles:" -ForegroundColor Cyan
                Write-Host "  [1] Camera"
                Write-Host "  [2] Microphone"
                Write-Host "  [3] Location"
                Write-Host "  [4] Contacts"
                Write-Host "  [5] Calendar"
                
                $permChoice = Read-Host "`n  Seleccione permiso (1-5)"
                $permissions = @("Camera", "Microphone", "Location", "Contacts", "Calendar")
                
                if ([int]$permChoice -ge 1 -and [int]$permChoice -le 5) {
                    $selectedPerm = $permissions[[int]$permChoice - 1]
                    
                    Write-Host "`n  [1] Permitir"
                    Write-Host "  [2] Denegar"
                    $actionChoice = Read-Host "  Seleccione acción (1-2)"
                    
                    $action = if ($actionChoice -eq '1') { "Allow" } else { "Deny" }
                    Set-AppPermission -Permission $selectedPerm -Action $action
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                Disable-TelemetryAdvanced | Out-Null
                Write-Host "`n[i] Se recomienda reiniciar el sistema para aplicar todos los cambios" -ForegroundColor Yellow
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                Clear-ActivityHistory | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                Get-ActiveConnections | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '7' {
                Write-Host "`n[*] Recopilando información completa..." -ForegroundColor Cyan
                
                $appPerms = Get-AppPermissions
                $telemetryResult = @{ TotalKeys = 0; ConfiguredKeys = 0; Success = $true }
                $activityDeleted = 0
                $connectionsData = Get-ActiveConnections
                
                $reportResult = Export-PrivacyReport -AppPermissions $appPerms -TelemetryResult $telemetryResult `
                    -ActivityItemsDeleted $activityDeleted -ConnectionsData $connectionsData
                
                Write-Host "`n[✓] Reporte completo generado" -ForegroundColor Green
                Write-Host "  Puntuación de Privacidad: $($reportResult.PrivacyScore)/100" -ForegroundColor Cyan
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '8' {
                Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Red
                Write-Host "║  ⚠️  MODO MÁXIMA PRIVACIDAD                    ║" -ForegroundColor Red
                Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Red
                Write-Host "║  Se ejecutarán TODAS las acciones:            ║" -ForegroundColor Yellow
                Write-Host "║  • Denegar todos los permisos de apps         ║" -ForegroundColor Yellow
                Write-Host "║  • Desactivar telemetría completa             ║" -ForegroundColor Yellow
                Write-Host "║  • Limpiar historial de actividad             ║" -ForegroundColor Yellow
                Write-Host "║  • Generar reporte de privacidad              ║" -ForegroundColor Yellow
                Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Red
                Write-Host ""
                
                $confirm = Read-Host "¿Confirmar MODO MÁXIMA PRIVACIDAD? (S/N)"
                
                if ($confirm -eq 'S' -or $confirm -eq 's') {
                    Write-Host "`n[*] Ejecutando modo máxima privacidad..." -ForegroundColor Cyan
                    
                    # 1. Denegar todos los permisos
                    Write-Host "`n[1/4] Denegando permisos de aplicaciones..." -ForegroundColor Cyan
                    foreach ($permission in @("Camera", "Microphone", "Location", "Contacts", "Calendar")) {
                        Set-AppPermission -Permission $permission -Action "Deny" | Out-Null
                    }
                    
                    # 2. Desactivar telemetría
                    Write-Host "`n[2/4] Desactivando telemetría..." -ForegroundColor Cyan
                    $telemetryResult = Disable-TelemetryAdvanced
                    
                    # 3. Limpiar historial
                    Write-Host "`n[3/4] Limpiando historial..." -ForegroundColor Cyan
                    $activityDeleted = Clear-ActivityHistory
                    
                    # 4. Generar reporte
                    Write-Host "`n[4/4] Generando reporte..." -ForegroundColor Cyan
                    $appPerms = Get-AppPermissions
                    $connectionsData = Get-ActiveConnections
                    
                    $reportResult = Export-PrivacyReport -AppPermissions $appPerms -TelemetryResult $telemetryResult `
                        -ActivityItemsDeleted $activityDeleted -ConnectionsData $connectionsData
                    
                    Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Green
                    Write-Host "║  ✓ MODO MÁXIMA PRIVACIDAD COMPLETADO          ║" -ForegroundColor Green
                    Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Green
                    Write-Host "║  Puntuación Final: $($reportResult.PrivacyScore)/100                        ║" -ForegroundColor Cyan
                    Write-Host "║  Reporte guardado en Desktop                   ║" -ForegroundColor Cyan
                    Write-Host "║                                                ║" -ForegroundColor Green
                    Write-Host "║  ⚠️  Se recomienda REINICIAR el sistema         ║" -ForegroundColor Yellow
                    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                Write-Host "`n  [✓] Saliendo del Centro de Privacidad..." -ForegroundColor Green
                Write-Log "Centro de Privacidad cerrado" "INFO"
                return
            }
            default {
                Write-Host "`n  [✗] Opción inválida" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "`n[✗] ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Host "[i] Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'" -ForegroundColor Yellow
    Read-Host "`nPresione ENTER para salir"
    exit 1
}

# Iniciar menú
Show-Menu

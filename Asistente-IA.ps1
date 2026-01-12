<#
.SYNOPSIS
    Asistente Inteligente para Diagnóstico y Soluciones
.DESCRIPTION
    Analiza logs del sistema, detecta patrones de errores, ofrece soluciones basadas
    en una base de conocimiento de problemas comunes de Windows y prioriza acciones.
.NOTES
    Versión: 3.0.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11, Permisos de Administrador
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:AssistantVersion = "3.0.0"
$Global:KnowledgeBasePath = "$env:USERPROFILE\OptimizadorPC-KnowledgeBase.json"
$Global:DiagnosticReportPath = "$env:USERPROFILE\OptimizadorPC-DiagnosticReport.html"

# Importar Logger si existe
if (Test-Path ".\Logger.ps1") {
    . ".\Logger.ps1"
    $Global:UseLogger = $true
} else {
    $Global:UseLogger = $false
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
}

# Base de conocimiento de errores comunes
$Global:KnowledgeBase = @{
    # Errores de sistema
    "KERNEL_DATA_INPAGE_ERROR" = @{
        Severity = "Critical"
        Category = "Hardware"
        Description = "Error crítico de lectura de memoria o disco"
        Symptoms = @("BSOD", "Pantalla azul", "Reinicio inesperado")
        Solutions = @(
            "Ejecutar Check Disk: chkdsk /f /r C:",
            "Verificar RAM con Windows Memory Diagnostic",
            "Actualizar drivers de almacenamiento",
            "Revisar cables y conexiones del disco duro"
        )
        Priority = 1
    }
    "DRIVER_IRQL_NOT_LESS_OR_EQUAL" = @{
        Severity = "High"
        Category = "Drivers"
        Description = "Driver intentó acceder a memoria inválida"
        Symptoms = @("BSOD", "Congelamiento", "Pantalla azul")
        Solutions = @(
            "Actualizar todos los drivers del sistema",
            "Desinstalar driver problemático en Modo Seguro",
            "Verificar actualizaciones de Windows",
            "Restaurar sistema a punto anterior"
        )
        Priority = 2
    }
    "PAGE_FAULT_IN_NONPAGED_AREA" = @{
        Severity = "High"
        Category = "Memory"
        Description = "Fallo al acceder a área de memoria no paginada"
        Symptoms = @("BSOD", "Aplicaciones cerrándose", "Lentitud extrema")
        Solutions = @(
            "Ejecutar sfc /scannow para reparar archivos del sistema",
            "Verificar RAM con memtest86",
            "Desinstalar software recientemente instalado",
            "Actualizar BIOS/UEFI"
        )
        Priority = 1
    }
    "SYSTEM_SERVICE_EXCEPTION" = @{
        Severity = "Medium"
        Category = "Services"
        Description = "Excepción en servicio del sistema"
        Symptoms = @("BSOD ocasional", "Servicios fallando")
        Solutions = @(
            "Actualizar Windows completamente",
            "Ejecutar DISM /Online /Cleanup-Image /RestoreHealth",
            "Verificar Event Viewer para identificar servicio específico",
            "Deshabilitar servicios no esenciales"
        )
        Priority = 3
    }
    "DPC_WATCHDOG_VIOLATION" = @{
        Severity = "Medium"
        Category = "Drivers"
        Description = "Driver tardó demasiado en completar operación"
        Symptoms = @("BSOD", "Sistema congelado temporalmente")
        Solutions = @(
            "Actualizar drivers de SSD/NVMe",
            "Actualizar chipset drivers",
            "Desactivar Fast Startup",
            "Verificar firmware del SSD"
        )
        Priority = 2
    }
    "Windows Update" = @{
        Severity = "Low"
        Category = "Updates"
        Description = "Problemas con Windows Update"
        Symptoms = @("Actualizaciones fallando", "Error 0x80070057", "Error 0x800f0922")
        Solutions = @(
            "Ejecutar Windows Update Troubleshooter",
            "Eliminar caché: net stop wuauserv; rd /s %windir%\SoftwareDistribution",
            "Ejecutar DISM /Online /Cleanup-Image /RestoreHealth",
            "Reiniciar servicios: net start wuauserv"
        )
        Priority = 4
    }
    "High CPU Usage" = @{
        Severity = "Medium"
        Category = "Performance"
        Description = "Uso excesivo de CPU"
        Symptoms = @("Sistema lento", "Ventiladores a máxima velocidad", "Aplicaciones lentas")
        Solutions = @(
            "Identificar proceso culpable en Task Manager",
            "Desactivar programas de inicio innecesarios",
            "Escanear malware con Windows Defender",
            "Actualizar o reinstalar aplicación problemática"
        )
        Priority = 3
    }
    "High Memory Usage" = @{
        Severity = "Medium"
        Category = "Performance"
        Description = "Uso excesivo de memoria RAM"
        Symptoms = @("Sistema lento", "Aplicaciones cerrándose", "Uso de disco alto")
        Solutions = @(
            "Cerrar aplicaciones no utilizadas",
            "Desactivar servicios innecesarios",
            "Aumentar archivo de paginación",
            "Considerar upgrade de RAM"
        )
        Priority = 3
    }
    "Disk 100%" = @{
        Severity = "High"
        Category = "Performance"
        Description = "Disco al 100% en Task Manager"
        Symptoms = @("Sistema extremadamente lento", "Congelamiento", "Tiempos de carga largos")
        Solutions = @(
            "Desactivar Windows Search temporalmente",
            "Desactivar Superfetch/SysMain",
            "Ejecutar chkdsk /f /r",
            "Considerar upgrade a SSD",
            "Escanear malware"
        )
        Priority = 1
    }
    "Network Connectivity" = @{
        Severity = "Medium"
        Category = "Network"
        Description = "Problemas de conexión de red"
        Symptoms = @("Sin internet", "Conexión intermitente", "DNS no resuelve")
        Solutions = @(
            "Ejecutar ipconfig /flushdns",
            "Reiniciar adaptador: ipconfig /release && ipconfig /renew",
            "Restablecer Winsock: netsh winsock reset",
            "Actualizar drivers de red",
            "Cambiar DNS a 8.8.8.8 y 8.8.4.4"
        )
        Priority = 2
    }
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                                              ║" -ForegroundColor Green
    Write-Host "  ║          🤖 ASISTENTE INTELIGENTE DE DIAGNÓSTICO            ║" -ForegroundColor White
    Write-Host "  ║                     Versión $Global:AssistantVersion                      ║" -ForegroundColor Green
    Write-Host "  ║                                                              ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

function Get-EventLogErrors {
    <#
    .SYNOPSIS
        Obtiene errores críticos del Event Log
    #>
    param(
        [int]$MaxEvents = 100,
        [int]$DaysBack = 7
    )
    
    Write-Host "`n[*] Analizando Event Logs (últimos $DaysBack días)..." -ForegroundColor Cyan
    Write-Log "Analizando Event Logs" "INFO"
    
    $startDate = (Get-Date).AddDays(-$DaysBack)
    $errors = @()
    
    try {
        # System Log
        Write-Host "  [1/3] Analizando System log..." -ForegroundColor Yellow
        $systemErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1,2,3  # Critical, Error, Warning
            StartTime = $startDate
        } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
        
        $errors += $systemErrors | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                Level = $_.LevelDisplayName
                Source = $_.ProviderName
                EventId = $_.Id
                Message = $_.Message
                LogName = "System"
            }
        }
        
        # Application Log
        Write-Host "  [2/3] Analizando Application log..." -ForegroundColor Yellow
        $appErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Level = 1,2,3
            StartTime = $startDate
        } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
        
        $errors += $appErrors | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                Level = $_.LevelDisplayName
                Source = $_.ProviderName
                EventId = $_.Id
                Message = $_.Message
                LogName = "Application"
            }
        }
        
        # Security Log (solo críticos)
        Write-Host "  [3/3] Analizando Security log..." -ForegroundColor Yellow
        $securityErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            Level = 1,2
            StartTime = $startDate
        } -MaxEvents 50 -ErrorAction SilentlyContinue
        
        $errors += $securityErrors | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                Level = $_.LevelDisplayName
                Source = $_.ProviderName
                EventId = $_.Id
                Message = $_.Message
                LogName = "Security"
            }
        }
        
        $totalErrors = $errors.Count
        Write-Host "  [✓] $totalErrors error(es) encontrado(s)" -ForegroundColor Green
        Write-Log "Encontrados $totalErrors errores en Event Logs" "INFO"
        
        return $errors | Sort-Object TimeCreated -Descending
    }
    catch {
        Write-Host "  [✗] Error analizando logs: $_" -ForegroundColor Red
        Write-Log "Error analizando Event Logs: $_" "ERROR"
        return @()
    }
}

function Find-ErrorPatterns {
    <#
    .SYNOPSIS
        Busca patrones conocidos en los errores
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Errors
    )
    
    Write-Host "`n[*] Buscando patrones conocidos..." -ForegroundColor Cyan
    Write-Log "Analizando patrones de errores" "INFO"
    
    $findings = @()
    
    foreach ($errorItem in $Errors) {
        $message = $errorItem.Message
        
        foreach ($pattern in $Global:KnowledgeBase.Keys) {
            if ($message -match $pattern) {
                $kb = $Global:KnowledgeBase[$pattern]
                
                $findings += [PSCustomObject]@{
                    Pattern = $pattern
                    Severity = $kb.Severity
                    Category = $kb.Category
                    Description = $kb.Description
                    Symptoms = $kb.Symptoms
                    Solutions = $kb.Solutions
                    Priority = $kb.Priority
                    FoundIn = $error.LogName
                    TimeCreated = $error.TimeCreated
                    Count = 1
                }
            }
        }
    }
    
    # Agrupar por patrón y contar ocurrencias
    $groupedFindings = $findings | Group-Object Pattern | ForEach-Object {
        $first = $_.Group[0]
        [PSCustomObject]@{
            Pattern = $first.Pattern
            Severity = $first.Severity
            Category = $first.Category
            Description = $first.Description
            Symptoms = $first.Symptoms
            Solutions = $first.Solutions
            Priority = $first.Priority
            Count = $_.Count
            LastOccurrence = ($_.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
        }
    }
    
    $totalPatterns = $groupedFindings.Count
    Write-Host "  [✓] $totalPatterns patrón(es) identificado(s)" -ForegroundColor Green
    Write-Log "Identificados $totalPatterns patrones conocidos" "INFO"
    
    return $groupedFindings | Sort-Object Priority, Count -Descending
}

function Get-SystemHealthScore {
    <#
    .SYNOPSIS
        Calcula puntuación de salud del sistema
    #>
    Write-Host "`n[*] Calculando puntuación de salud del sistema..." -ForegroundColor Cyan
    
    $score = 100
    $issues = @()
    
    try {
        # CPU
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue
        if ($cpuUsage -gt 80) {
            $score -= 10
            $issues += "CPU al $([math]::Round($cpuUsage, 0))% (alto)"
        }
        
        # Memoria
        $os = Get-CimInstance Win32_OperatingSystem
        $memoryUsage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 0)
        if ($memoryUsage -gt 85) {
            $score -= 10
            $issues += "Memoria al $memoryUsage% (alta)"
        }
        
        # Disco
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($disk in $disks) {
            $diskUsage = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 0)
            if ($diskUsage -gt 90) {
                $score -= 5
                $issues += "Disco $($disk.DeviceID) al $diskUsage% (lleno)"
            }
        }
        
        # Servicios críticos
        $criticalServices = @("wuauserv", "BITS", "Winmgmt", "Dnscache", "MpsSvc", "EventLog")
        foreach ($serviceName in $criticalServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.Status -ne "Running") {
                $score -= 5
                $issues += "Servicio $($service.DisplayName) detenido"
            }
        }
        
        # Errores recientes
        $recentErrors = Get-EventLogErrors -MaxEvents 50 -DaysBack 1
        $criticalErrors = ($recentErrors | Where-Object { $_.Level -eq "Critical" }).Count
        if ($criticalErrors -gt 0) {
            $score -= ($criticalErrors * 3)
            $issues += "$criticalErrors error(es) crítico(s) en últimas 24h"
        }
        
        # Windows Update
        $updateService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        if ($updateService.Status -ne "Running") {
            $score -= 5
            $issues += "Windows Update deshabilitado"
        }
        
        # Limitar score mínimo
        if ($score -lt 0) { $score = 0 }
        
        $scoreLevel = if ($score -ge 80) { "Excelente" } 
                     elseif ($score -ge 60) { "Bueno" }
                     elseif ($score -ge 40) { "Regular" }
                     else { "Crítico" }
        
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║         PUNTUACIÓN DE SALUD DEL SISTEMA            ║" -ForegroundColor White
        Write-Host "╠════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  Puntuación: $score / 100 - $scoreLevel".PadRight(53) + "║" -ForegroundColor $(if ($score -ge 80) { "Green" } elseif ($score -ge 60) { "Yellow" } else { "Red" })
        Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        
        if ($issues.Count -gt 0) {
            Write-Host ""
            Write-Host "  Problemas detectados:" -ForegroundColor Yellow
            foreach ($issue in $issues) {
                Write-Host "  • $issue" -ForegroundColor Gray
            }
        }
        
        Write-Log "Health Score: $score/100 - $scoreLevel, $($issues.Count) issues" "INFO"
        
        return @{
            Score = $score
            Level = $scoreLevel
            Issues = $issues
        }
    }
    catch {
        Write-Host "  [✗] Error calculando health score: $_" -ForegroundColor Red
        Write-Log "Error calculando health score: $_" "ERROR"
        return @{ Score = 0; Level = "Error"; Issues = @() }
    }
}

function Show-Recommendations {
    <#
    .SYNOPSIS
        Muestra recomendaciones basadas en findings
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Findings
    )
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              RECOMENDACIONES INTELIGENTES                              ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $recNumber = 0
    
    foreach ($finding in $Findings | Select-Object -First 10) {
        $recNumber++
        
        $severityColor = switch ($finding.Severity) {
            "Critical" { "Red" }
            "High" { "Yellow" }
            "Medium" { "Cyan" }
            default { "Gray" }
        }
        
        Write-Host "  [$recNumber] $($finding.Pattern)" -ForegroundColor $severityColor
        Write-Host "      Severidad: $($finding.Severity) | Categoría: $($finding.Category)" -ForegroundColor Gray
        Write-Host "      Ocurrencias: $($finding.Count) veces | Última: $($finding.LastOccurrence.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        Write-Host "      Descripción: $($finding.Description)" -ForegroundColor White
        Write-Host ""
        Write-Host "      Soluciones sugeridas:" -ForegroundColor Green
        
        $solNumber = 0
        foreach ($solution in $finding.Solutions) {
            $solNumber++
            Write-Host "      $solNumber. $solution" -ForegroundColor Cyan
        }
        
        Write-Host ""
    }
}

function Export-DiagnosticReport {
    <#
    .SYNOPSIS
        Exporta reporte completo en HTML
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Errors,
        
        [Parameter(Mandatory=$true)]
        [array]$Findings,
        
        [Parameter(Mandatory=$true)]
        $HealthScore
    )
    
    Write-Host "`n[*] Generando reporte de diagnóstico..." -ForegroundColor Cyan
    
    $reportPath = "$env:USERPROFILE\OptimizadorPC-Diagnostico-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Diagnóstico - Optimizador PC</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .score-section {
            background: #f8f9fa;
            padding: 40px;
            text-align: center;
        }
        .score-circle {
            width: 200px;
            height: 200px;
            margin: 0 auto;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 4em;
            font-weight: bold;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .score-label {
            margin-top: 20px;
            font-size: 1.5em;
            color: #666;
        }
        .findings-section {
            padding: 40px;
        }
        .finding-card {
            background: #f8f9fa;
            border-left: 5px solid #667eea;
            padding: 20px;
            margin: 15px 0;
            border-radius: 8px;
        }
        .finding-card.critical {
            border-left-color: #e74c3c;
        }
        .finding-card.high {
            border-left-color: #f39c12;
        }
        .finding-card.medium {
            border-left-color: #3498db;
        }
        .finding-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .finding-title {
            font-size: 1.3em;
            font-weight: 600;
            color: #333;
        }
        .badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            color: white;
        }
        .badge.critical { background: #e74c3c; }
        .badge.high { background: #f39c12; }
        .badge.medium { background: #3498db; }
        .badge.low { background: #95a5a6; }
        .solutions {
            margin-top: 15px;
        }
        .solution-item {
            background: white;
            padding: 12px;
            margin: 8px 0;
            border-radius: 5px;
            border-left: 3px solid #2ecc71;
        }
        .errors-section {
            padding: 40px;
            background: #f8f9fa;
        }
        .error-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background: white;
        }
        .error-table th {
            background: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
        }
        .error-table td {
            padding: 12px;
            border-bottom: 1px solid #e0e0e0;
        }
        .error-table tr:hover {
            background: #f8f9fa;
        }
        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 Reporte de Diagnóstico Inteligente</h1>
            <p>Optimizador de Computadora v$Global:AssistantVersion</p>
            <p>Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        </div>
        
        <div class="score-section">
            <div class="score-circle">$($HealthScore.Score)</div>
            <div class="score-label">$($HealthScore.Level)</div>
        </div>
        
        <div class="findings-section">
            <h2>🔍 Problemas Identificados</h2>
"@
    
    foreach ($finding in $Findings) {
        $severityClass = $finding.Severity.ToLower()
        
        $html += @"
            <div class="finding-card $severityClass">
                <div class="finding-header">
                    <div class="finding-title">$($finding.Pattern)</div>
                    <div>
                        <span class="badge $severityClass">$($finding.Severity)</span>
                        <span class="badge">$($finding.Category)</span>
                        <span class="badge">$($finding.Count) ocurrencias</span>
                    </div>
                </div>
                <p><strong>Descripción:</strong> $($finding.Description)</p>
                <p><strong>Última ocurrencia:</strong> $($finding.LastOccurrence.ToString('yyyy-MM-dd HH:mm:ss'))</p>
                <div class="solutions">
                    <strong>Soluciones recomendadas:</strong>
"@
        
        foreach ($solution in $finding.Solutions) {
            $html += @"
                    <div class="solution-item">✓ $solution</div>
"@
        }
        
        $html += @"
                </div>
            </div>
"@
    }
    
    $html += @"
        </div>
        
        <div class="errors-section">
            <h2>📋 Errores Recientes (Top 20)</h2>
            <table class="error-table">
                <thead>
                    <tr>
                        <th>Fecha</th>
                        <th>Nivel</th>
                        <th>Fuente</th>
                        <th>Mensaje</th>
                    </tr>
                </thead>
                <tbody>
"@
    
    foreach ($errorItem in ($Errors | Select-Object -First 20)) {
        $html += @"
                    <tr>
                        <td>$($errorItem.TimeCreated.ToString('yyyy-MM-dd HH:mm'))</td>
                        <td>$($errorItem.Level)</td>
                        <td>$($errorItem.Source)</td>
                        <td>$($errorItem.Message.Substring(0, [Math]::Min(100, $errorItem.Message.Length)))...</td>
                    </tr>
"@
    }
    
    $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>Optimizador de Computadora - Asistente IA</p>
            <p>Este reporte fue generado automáticamente</p>
        </div>
    </div>
</body>
</html>
"@
    
    try {
        $html | Out-File -FilePath $reportPath -Encoding UTF8 -ErrorAction Stop
        Write-Host "  [✓] Reporte generado: $reportPath" -ForegroundColor Green
        Write-Log "Reporte de diagnóstico generado: $reportPath" "SUCCESS"
        
        Write-Host ""
        $openReport = Read-Host "¿Desea abrir el reporte? (S/N)"
        
        if ($openReport -eq "S" -or $openReport -eq "s") {
            Start-Process $reportPath
        }
    }
    catch {
        Write-Host "  [✗] Error generando reporte: $_" -ForegroundColor Red
        Write-Log "Error generando reporte: $_" "ERROR"
    }
}

function Start-AutomaticFix {
    <#
    .SYNOPSIS
        Intenta aplicar correcciones automáticas
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Findings
    )
    
    Write-Host "`n[*] Iniciando correcciones automáticas..." -ForegroundColor Cyan
    Write-Log "Iniciando correcciones automáticas" "INFO"
    
    Write-Host ""
    $confirmation = Read-Host "¿Está seguro de aplicar correcciones automáticas? (S/N)"
    
    if ($confirmation -ne "S" -and $confirmation -ne "s") {
        Write-Host "  [i] Operación cancelada" -ForegroundColor Yellow
        return
    }
    
    $fixedCount = 0
    $failedCount = 0
    
    # Correcciones comunes
    $automaticFixes = @{
        "Windows Update" = {
            Write-Host "`n  [*] Reiniciando Windows Update..." -ForegroundColor Yellow
            net stop wuauserv | Out-Null
            Start-Sleep -Seconds 2
            net start wuauserv | Out-Null
            return $true
        }
        "Disk 100%" = {
            Write-Host "`n  [*] Desactivando Windows Search temporalmente..." -ForegroundColor Yellow
            Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
            return $true
        }
        "High CPU Usage" = {
            Write-Host "`n  [*] Optimizando servicios..." -ForegroundColor Yellow
            Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -ne "Running" } | Start-Service -ErrorAction SilentlyContinue
            return $true
        }
        "Network Connectivity" = {
            Write-Host "`n  [*] Reiniciando stack de red..." -ForegroundColor Yellow
            ipconfig /flushdns | Out-Null
            netsh winsock reset | Out-Null
            return $true
        }
    }
    
    foreach ($finding in $Findings) {
        if ($automaticFixes.ContainsKey($finding.Pattern)) {
            try {
                $result = & $automaticFixes[$finding.Pattern]
                
                if ($result) {
                    Write-Host "  [✓] Corrección aplicada: $($finding.Pattern)" -ForegroundColor Green
                    Write-Log "Corrección aplicada: $($finding.Pattern)" "SUCCESS"
                    $fixedCount++
                }
            }
            catch {
                Write-Host "  [✗] Error en corrección: $($finding.Pattern)" -ForegroundColor Red
                Write-Log "Error en corrección automática: $_" "ERROR"
                $failedCount++
            }
        }
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          RESUMEN DE CORRECCIONES                   ║" -ForegroundColor White
    Write-Host "╠════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Correcciones exitosas: $fixedCount".PadRight(53) + "║" -ForegroundColor Green
    Write-Host "║  Correcciones fallidas: $failedCount".PadRight(53) + "║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if ($fixedCount -gt 0) {
        Write-Host ""
        Write-Host "  [i] Se recomienda reiniciar el sistema para aplicar todos los cambios" -ForegroundColor Yellow
    }
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 🔍 Diagnóstico Completo                   ║" -ForegroundColor Cyan
        Write-Host "  ║  [2] 📊 Análisis de Event Logs                 ║" -ForegroundColor Blue
        Write-Host "  ║  [3] 💯 Puntuación de Salud del Sistema        ║" -ForegroundColor Green
        Write-Host "  ║  [4] 🤖 Recomendaciones Inteligentes           ║" -ForegroundColor Yellow
        Write-Host "  ║  [5] 🔧 Aplicar Correcciones Automáticas       ║" -ForegroundColor Magenta
        Write-Host "  ║  [6] 📄 Exportar Reporte HTML                  ║" -ForegroundColor White
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                $errors = Get-EventLogErrors -MaxEvents 200 -DaysBack 7
                
                if ($errors.Count -gt 0) {
                    $findings = Find-ErrorPatterns -Errors $errors
                    
                    if ($findings.Count -gt 0) {
                        Show-Recommendations -Findings $findings
                    }
                    else {
                        Write-Host "`n  [✓] No se encontraron patrones conocidos" -ForegroundColor Green
                    }
                    
                    $healthScore = Get-SystemHealthScore
                    
                    Write-Host ""
                    $exportChoice = Read-Host "¿Desea exportar reporte HTML? (S/N)"
                    
                    if ($exportChoice -eq "S" -or $exportChoice -eq "s") {
                        Export-DiagnosticReport -Errors $errors -Findings $findings -HealthScore $healthScore
                    }
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '2' {
                Get-EventLogErrors -MaxEvents 200 -DaysBack 7 | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                Get-SystemHealthScore | Out-Null
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                $errors = Get-EventLogErrors -MaxEvents 200 -DaysBack 7
                
                if ($errors.Count -gt 0) {
                    $findings = Find-ErrorPatterns -Errors $errors
                    
                    if ($findings.Count -gt 0) {
                        Show-Recommendations -Findings $findings
                    }
                    else {
                        Write-Host "`n  [✓] No se encontraron patrones conocidos" -ForegroundColor Green
                    }
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                $errors = Get-EventLogErrors -MaxEvents 200 -DaysBack 7
                
                if ($errors.Count -gt 0) {
                    $findings = Find-ErrorPatterns -Errors $errors
                    
                    if ($findings.Count -gt 0) {
                        Start-AutomaticFix -Findings $findings
                    }
                    else {
                        Write-Host "`n  [✓] No hay problemas conocidos para corregir" -ForegroundColor Green
                    }
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                $errors = Get-EventLogErrors -MaxEvents 200 -DaysBack 7
                
                if ($errors.Count -gt 0) {
                    $findings = Find-ErrorPatterns -Errors $errors
                    $healthScore = Get-SystemHealthScore
                    Export-DiagnosticReport -Errors $errors -Findings $findings -HealthScore $healthScore
                }
                else {
                    Write-Host "`n  [i] No hay datos para exportar" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                Write-Host "`n  [✓] Saliendo del Asistente IA..." -ForegroundColor Green
                Write-Log "Asistente IA cerrado" "INFO"
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

<#
.SYNOPSIS
    Dashboard Web con API REST para Optimizador de PC
.DESCRIPTION
    Servidor HTTP con API REST para monitoreo remoto del sistema,
    WebSockets para actualizaciones en tiempo real y autenticación básica.
.NOTES
    Versión: 3.0.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11, Permisos de Administrador
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:DashboardVersion = "3.0.0"
$Global:HttpListener = $null
$Global:ServerRunning = $false
$Global:Port = 8080
$Global:ApiKey = "OptimizadorPC-$(New-Guid)"
$Global:WebSocketClients = @()

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
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "  ║                                                              ║" -ForegroundColor Blue
    Write-Host "  ║          🌐 DASHBOARD WEB - API REST                        ║" -ForegroundColor White
    Write-Host "  ║                   Versión $Global:DashboardVersion                      ║" -ForegroundColor Blue
    Write-Host "  ║                                                              ║" -ForegroundColor Blue
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Get-SystemMetrics {
    <#
    .SYNOPSIS
        Obtiene métricas del sistema en tiempo real
    #>
    try {
        # CPU
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue
        
        # Memoria
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMemoryGB = $totalMemoryGB - $freeMemoryGB
        $memoryUsagePercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
        
        # Disco
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop | ForEach-Object {
            @{
                Drive = $_.DeviceID
                TotalGB = [math]::Round($_.Size / 1GB, 2)
                FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
                UsagePercent = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
            }
        }
        
        # Red
        $adapters = Get-NetAdapterStatistics -ErrorAction Stop | Select-Object -First 1
        $networkSentMB = if ($adapters) { [math]::Round($adapters.SentBytes / 1MB, 2) } else { 0 }
        $networkRecvMB = if ($adapters) { [math]::Round($adapters.ReceivedBytes / 1MB, 2) } else { 0 }
        
        # Procesos
        $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
            @{
                Name = $_.ProcessName
                CPU = [math]::Round($_.CPU, 2)
                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
                Id = $_.Id
            }
        }
        
        return @{
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            CPU = @{
                UsagePercent = [math]::Round($cpuUsage, 2)
            }
            Memory = @{
                TotalGB = $totalMemoryGB
                UsedGB = $usedMemoryGB
                FreeGB = $freeMemoryGB
                UsagePercent = $memoryUsagePercent
            }
            Disks = $disks
            Network = @{
                SentMB = $networkSentMB
                ReceivedMB = $networkRecvMB
            }
            TopProcesses = $processes
        }
    }
    catch {
        Write-Log "Error obteniendo métricas: $_" "ERROR"
        return @{ Error = $_.Exception.Message }
    }
}

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Obtiene información general del sistema
    #>
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $bios = Get-CimInstance Win32_BIOS
        
        return @{
            ComputerName = $env:COMPUTERNAME
            OS = @{
                Name = $os.Caption
                Version = $os.Version
                Build = $os.BuildNumber
                Architecture = $os.OSArchitecture
            }
            Hardware = @{
                Manufacturer = $cs.Manufacturer
                Model = $cs.Model
                TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                Processors = $cs.NumberOfProcessors
                LogicalProcessors = $cs.NumberOfLogicalProcessors
            }
            CPU = @{
                Name = $cpu.Name
                Cores = $cpu.NumberOfCores
                LogicalProcessors = $cpu.NumberOfLogicalProcessors
                MaxClockSpeed = $cpu.MaxClockSpeed
            }
            BIOS = @{
                Manufacturer = $bios.Manufacturer
                Version = $bios.SMBIOSBIOSVersion
                ReleaseDate = $bios.ReleaseDate
            }
            Uptime = @{
                Days = [math]::Round((Get-Date) - $os.LastBootUpTime).TotalDays, 2)
                Hours = [math]::Round((Get-Date) - $os.LastBootUpTime).TotalHours, 2)
            }
        }
    }
    catch {
        Write-Log "Error obteniendo información del sistema: $_" "ERROR"
        return @{ Error = $_.Exception.Message }
    }
}

function Get-Services {
    <#
    .SYNOPSIS
        Obtiene estado de servicios críticos
    #>
    $criticalServices = @("wuauserv", "BITS", "Winmgmt", "Dnscache", "MpsSvc", "EventLog")
    
    $services = $criticalServices | ForEach-Object {
        $service = Get-Service -Name $_ -ErrorAction SilentlyContinue
        
        if ($service) {
            @{
                Name = $service.Name
                DisplayName = $service.DisplayName
                Status = $service.Status.ToString()
                StartType = $service.StartType.ToString()
            }
        }
    }
    
    return @{
        Services = $services
        Total = $services.Count
        Running = ($services | Where-Object { $_.Status -eq "Running" }).Count
        Stopped = ($services | Where-Object { $_.Status -eq "Stopped" }).Count
    }
}

function Get-HTMLDashboard {
    <#
    .SYNOPSIS
        Genera HTML del dashboard principal
    #>
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Optimizador de PC</title>
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
        }
        .header {
            background: rgba(255,255,255,0.95);
            padding: 30px;
            border-radius: 15px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .header h1 {
            font-size: 2em;
            color: #667eea;
        }
        .status-badge {
            background: #2ecc71;
            color: white;
            padding: 10px 20px;
            border-radius: 25px;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .status-indicator {
            width: 12px;
            height: 12px;
            background: white;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .metric-card {
            background: rgba(255,255,255,0.95);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s;
        }
        .metric-card:hover {
            transform: translateY(-5px);
        }
        .metric-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .metric-title {
            font-size: 1.1em;
            color: #666;
            font-weight: 600;
        }
        .metric-icon {
            font-size: 2em;
        }
        .metric-value {
            font-size: 3em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 10px;
        }
        .metric-label {
            color: #999;
            font-size: 0.9em;
        }
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 15px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 1s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 0.8em;
            font-weight: bold;
        }
        .progress-fill.warning {
            background: linear-gradient(90deg, #f39c12 0%, #e67e22 100%);
        }
        .progress-fill.danger {
            background: linear-gradient(90deg, #e74c3c 0%, #c0392b 100%);
        }
        .processes-card {
            background: rgba(255,255,255,0.95);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 20px;
        }
        .processes-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .processes-table th {
            text-align: left;
            padding: 12px;
            background: #f8f9fa;
            font-weight: 600;
            color: #666;
        }
        .processes-table td {
            padding: 12px;
            border-bottom: 1px solid #e0e0e0;
        }
        .processes-table tr:hover {
            background: #f8f9fa;
        }
        .footer {
            text-align: center;
            color: white;
            margin-top: 20px;
            opacity: 0.8;
        }
        .refresh-info {
            text-align: center;
            color: white;
            margin-top: 10px;
            font-size: 0.9em;
        }
        .api-section {
            background: rgba(255,255,255,0.95);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 20px;
        }
        .api-endpoint {
            background: #f8f9fa;
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .api-method {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 5px 10px;
            border-radius: 5px;
            font-weight: bold;
            margin-right: 10px;
            font-size: 0.85em;
        }
    </style>
    <script>
        // Auto-refresh cada 5 segundos
        setInterval(function() {
            location.reload();
        }, 5000);
        
        // Actualizar timestamp
        function updateTime() {
            const now = new Date();
            document.getElementById('current-time').textContent = now.toLocaleString('es-ES');
        }
        
        setInterval(updateTime, 1000);
        window.onload = updateTime;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>🌐 Dashboard - Optimizador de PC</h1>
                <p id="current-time"></p>
            </div>
            <div class="status-badge">
                <div class="status-indicator"></div>
                <span>ONLINE</span>
            </div>
        </div>
        
        <div class="metrics-grid" id="metrics">
            <div class="metric-card">
                <div class="metric-header">
                    <span class="metric-title">CPU</span>
                    <span class="metric-icon">🖥️</span>
                </div>
                <div class="metric-value" id="cpu-value">--</div>
                <div class="metric-label">Uso del Procesador</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpu-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <span class="metric-title">Memoria RAM</span>
                    <span class="metric-icon">💾</span>
                </div>
                <div class="metric-value" id="memory-value">--</div>
                <div class="metric-label">Uso de Memoria</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="memory-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <span class="metric-title">Disco</span>
                    <span class="metric-icon">💿</span>
                </div>
                <div class="metric-value" id="disk-value">--</div>
                <div class="metric-label">Uso del Disco C:</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="disk-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <span class="metric-title">Red</span>
                    <span class="metric-icon">📡</span>
                </div>
                <div class="metric-value" id="network-sent">--</div>
                <div class="metric-label">MB Enviados</div>
                <div class="metric-value" id="network-recv" style="font-size: 2em; margin-top: 10px;">--</div>
                <div class="metric-label">MB Recibidos</div>
            </div>
        </div>
        
        <div class="processes-card">
            <h2>Top 5 Procesos por CPU</h2>
            <table class="processes-table" id="processes-table">
                <thead>
                    <tr>
                        <th>Proceso</th>
                        <th>PID</th>
                        <th>CPU</th>
                        <th>Memoria (MB)</th>
                    </tr>
                </thead>
                <tbody id="processes-body">
                    <tr><td colspan="4">Cargando...</td></tr>
                </tbody>
            </table>
        </div>
        
        <div class="api-section">
            <h2>📡 API REST Endpoints</h2>
            <div class="api-endpoint">
                <span class="api-method">GET</span>
                <code>/api/metrics</code> - Métricas del sistema en tiempo real
            </div>
            <div class="api-endpoint">
                <span class="api-method">GET</span>
                <code>/api/info</code> - Información general del sistema
            </div>
            <div class="api-endpoint">
                <span class="api-method">GET</span>
                <code>/api/services</code> - Estado de servicios críticos
            </div>
            <div class="api-endpoint">
                <span class="api-method">GET</span>
                <code>/api/processes</code> - Lista de procesos en ejecución
            </div>
        </div>
        
        <div class="refresh-info">
            🔄 Actualización automática cada 5 segundos
        </div>
        
        <div class="footer">
            <p>Optimizador de Computadora v$Global:DashboardVersion</p>
            <p>Dashboard Web - API REST</p>
        </div>
    </div>
    
    <script>
        // Cargar métricas al inicio
        fetch('/api/metrics')
            .then(response => response.json())
            .then(data => {
                // CPU
                document.getElementById('cpu-value').textContent = data.CPU.UsagePercent + '%';
                document.getElementById('cpu-progress').style.width = data.CPU.UsagePercent + '%';
                document.getElementById('cpu-progress').textContent = data.CPU.UsagePercent + '%';
                
                // Memoria
                document.getElementById('memory-value').textContent = data.Memory.UsagePercent + '%';
                document.getElementById('memory-progress').style.width = data.Memory.UsagePercent + '%';
                document.getElementById('memory-progress').textContent = data.Memory.UsagePercent + '%';
                
                // Disco
                if (data.Disks && data.Disks.length > 0) {
                    const diskC = data.Disks.find(d => d.Drive === 'C:') || data.Disks[0];
                    document.getElementById('disk-value').textContent = diskC.UsagePercent + '%';
                    document.getElementById('disk-progress').style.width = diskC.UsagePercent + '%';
                    document.getElementById('disk-progress').textContent = diskC.UsagePercent + '%';
                }
                
                // Red
                document.getElementById('network-sent').textContent = data.Network.SentMB;
                document.getElementById('network-recv').textContent = data.Network.ReceivedMB;
                
                // Procesos
                let processesHTML = '';
                data.TopProcesses.forEach(proc => {
                    processesHTML += '<tr><td>' + proc.Name + '</td><td>' + proc.Id + '</td><td>' + proc.CPU + '</td><td>' + proc.MemoryMB + '</td></tr>';
                });
                document.getElementById('processes-body').innerHTML = processesHTML;
            })
            .catch(error => {
                console.error('Error cargando métricas:', error);
            });
    </script>
</body>
</html>
"@
    
    return $html
}

function Start-WebServer {
    <#
    .SYNOPSIS
        Inicia servidor HTTP con API REST
    #>
    param(
        [int]$Port = 8080
    )
    
    Write-Host "`n[*] Iniciando servidor web en puerto $Port..." -ForegroundColor Cyan
    Write-Log "Iniciando servidor web en puerto $Port" "INFO"
    
    try {
        # Crear HttpListener
        $Global:HttpListener = New-Object System.Net.HttpListener
        $Global:HttpListener.Prefixes.Add("http://localhost:$Port/")
        $Global:HttpListener.Prefixes.Add("http://127.0.0.1:$Port/")
        $Global:HttpListener.Start()
        $Global:ServerRunning = $true
        $Global:Port = $Port
        
        Write-Host "  [✓] Servidor iniciado correctamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "  ╔════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "  ║          SERVIDOR WEB ACTIVO                       ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-Host "  ║  Dashboard: http://localhost:$Port".PadRight(54) + "║" -ForegroundColor Cyan
        Write-Host "  ║  API: http://localhost:$Port/api/metrics".PadRight(54) + "║" -ForegroundColor Cyan
        Write-Host "  ║  API Key: $Global:ApiKey".PadRight(54) + "║" -ForegroundColor Yellow
        Write-Host "  ╚════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [i] Presione CTRL+C para detener el servidor" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Log "Servidor web activo en http://localhost:$Port" "SUCCESS"
        
        # Loop de procesamiento de solicitudes
        while ($Global:ServerRunning) {
            try {
                $context = $Global:HttpListener.GetContext()
                $request = $context.Request
                $response = $context.Response
                
                $url = $request.Url.AbsolutePath
                $method = $request.HttpMethod
                
                Write-Host "  [$method] $url" -ForegroundColor Gray
                Write-Log "Request: $method $url" "INFO"
                
                # Configurar CORS
                $response.Headers.Add("Access-Control-Allow-Origin", "*")
                $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
                $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, X-API-Key")
                
                # Manejar rutas
                $responseContent = ""
                $contentType = "application/json"
                
                switch -Wildcard ($url) {
                    "/" {
                        $responseContent = Get-HTMLDashboard
                        $contentType = "text/html"
                    }
                    "/api/metrics" {
                        $metrics = Get-SystemMetrics
                        $responseContent = $metrics | ConvertTo-Json -Depth 10
                    }
                    "/api/info" {
                        $info = Get-SystemInfo
                        $responseContent = $info | ConvertTo-Json -Depth 10
                    }
                    "/api/services" {
                        $services = Get-Services
                        $responseContent = $services | ConvertTo-Json -Depth 10
                    }
                    "/api/processes" {
                        $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
                            @{
                                Name = $_.ProcessName
                                Id = $_.Id
                                CPU = [math]::Round($_.CPU, 2)
                                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
                            }
                        }
                        $responseContent = @{ Processes = $processes } | ConvertTo-Json -Depth 10
                    }
                    default {
                        $response.StatusCode = 404
                        $responseContent = @{ Error = "Endpoint not found" } | ConvertTo-Json
                    }
                }
                
                # Enviar respuesta
                $response.ContentType = $contentType
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseContent)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()
            }
            catch {
                if ($_.Exception.InnerException -is [System.Net.HttpListenerException]) {
                    # Listener cerrado, salir del loop
                    break
                }
                Write-Log "Error procesando request: $_" "ERROR"
            }
        }
    }
    catch {
        Write-Host "  [✗] Error al iniciar servidor: $_" -ForegroundColor Red
        Write-Log "Error iniciando servidor: $_" "ERROR"
        $Global:ServerRunning = $false
    }
}

function Stop-WebServer {
    <#
    .SYNOPSIS
        Detiene el servidor web
    #>
    Write-Host "`n[*] Deteniendo servidor web..." -ForegroundColor Cyan
    
    try {
        $Global:ServerRunning = $false
        
        if ($Global:HttpListener) {
            $Global:HttpListener.Stop()
            $Global:HttpListener.Close()
            $Global:HttpListener = $null
        }
        
        Write-Host "  [✓] Servidor detenido correctamente" -ForegroundColor Green
        Write-Log "Servidor web detenido" "SUCCESS"
    }
    catch {
        Write-Host "  [✗] Error al detener servidor: $_" -ForegroundColor Red
        Write-Log "Error deteniendo servidor: $_" "ERROR"
    }
}

function Test-APIEndpoint {
    <#
    .SYNOPSIS
        Prueba un endpoint de la API
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Endpoint
    )
    
    Write-Host "`n[*] Probando endpoint: $Endpoint..." -ForegroundColor Cyan
    
    try {
        $url = "http://localhost:$Global:Port$Endpoint"
        $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        
        Write-Host "  [✓] Respuesta recibida:" -ForegroundColor Green
        Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
    }
    catch {
        Write-Host "  [✗] Error: $_" -ForegroundColor Red
    }
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        $serverStatus = if ($Global:ServerRunning) { "🟢 ACTIVO" } else { "🔴 DETENIDO" }
        $serverPort = if ($Global:ServerRunning) { " (Puerto $Global:Port)" } else { "" }
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║  Estado: $serverStatus$serverPort".PadRight(53) + "║" -ForegroundColor $(if ($Global:ServerRunning) { "Green" } else { "Red" })
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 🚀 Iniciar Servidor Web                   ║" -ForegroundColor Green
        Write-Host "  ║  [2] 🛑 Detener Servidor                       ║" -ForegroundColor Red
        Write-Host "  ║  [3] 🌐 Abrir Dashboard en Navegador           ║" -ForegroundColor Cyan
        Write-Host "  ║  [4] 📊 Probar Endpoint /api/metrics           ║" -ForegroundColor Blue
        Write-Host "  ║  [5] 💻 Probar Endpoint /api/info              ║" -ForegroundColor Blue
        Write-Host "  ║  [6] ⚙️  Probar Endpoint /api/services         ║" -ForegroundColor Blue
        Write-Host "  ║  [7] 🔑 Mostrar API Key                        ║" -ForegroundColor Yellow
        Write-Host "  ║  [8] 🔄 Regenerar API Key                      ║" -ForegroundColor Magenta
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                if ($Global:ServerRunning) {
                    Write-Host "`n  [!] El servidor ya está activo" -ForegroundColor Yellow
                    Read-Host "`nPresione ENTER para continuar"
                }
                else {
                    $portInput = Read-Host "`n  Puerto (Enter para 8080)"
                    $port = if ([string]::IsNullOrWhiteSpace($portInput)) { 8080 } else { [int]$portInput }
                    
                    # Iniciar servidor en Job para no bloquear
                    Write-Host "`n  [*] Iniciando servidor en segundo plano..." -ForegroundColor Cyan
                    
                    $job = Start-Job -ScriptBlock {
                        param($Port)
                        & ".\Dashboard-Web.ps1" -Port $Port
                    } -ArgumentList $port
                    
                    Start-Sleep -Seconds 2
                    
                    Write-Host "  [✓] Servidor iniciado como Job ID: $($job.Id)" -ForegroundColor Green
                    Write-Host "  [i] Use 'Detener Servidor' para finalizar" -ForegroundColor Yellow
                    
                    $Global:ServerRunning = $true
                    $Global:Port = $port
                    
                    Read-Host "`nPresione ENTER para continuar"
                }
            }
            '2' {
                if (-not $Global:ServerRunning) {
                    Write-Host "`n  [!] El servidor no está activo" -ForegroundColor Yellow
                }
                else {
                    Stop-WebServer
                    
                    # Detener Jobs
                    Get-Job | Where-Object { $_.State -eq "Running" } | Stop-Job
                    Get-Job | Remove-Job -Force
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                if ($Global:ServerRunning) {
                    $url = "http://localhost:$Global:Port"
                    Write-Host "`n  [*] Abriendo $url..." -ForegroundColor Cyan
                    Start-Process $url
                }
                else {
                    Write-Host "`n  [!] El servidor no está activo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                if ($Global:ServerRunning) {
                    Test-APIEndpoint -Endpoint "/api/metrics"
                }
                else {
                    Write-Host "`n  [!] El servidor no está activo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                if ($Global:ServerRunning) {
                    Test-APIEndpoint -Endpoint "/api/info"
                }
                else {
                    Write-Host "`n  [!] El servidor no está activo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                if ($Global:ServerRunning) {
                    Test-APIEndpoint -Endpoint "/api/services"
                }
                else {
                    Write-Host "`n  [!] El servidor no está activo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '7' {
                Write-Host "`n  🔑 API Key actual:" -ForegroundColor Cyan
                Write-Host "     $Global:ApiKey" -ForegroundColor Yellow
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '8' {
                $Global:ApiKey = "OptimizadorPC-$(New-Guid)"
                Write-Host "`n  [✓] Nueva API Key generada:" -ForegroundColor Green
                Write-Host "     $Global:ApiKey" -ForegroundColor Yellow
                Write-Log "API Key regenerada" "INFO"
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                if ($Global:ServerRunning) {
                    Write-Host "`n  [*] Deteniendo servidor antes de salir..." -ForegroundColor Yellow
                    Stop-WebServer
                    Get-Job | Stop-Job
                    Get-Job | Remove-Job -Force
                }
                
                Write-Host "`n  [✓] Saliendo del Dashboard Web..." -ForegroundColor Green
                Write-Log "Dashboard Web cerrado" "INFO"
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

# ============================================
# Monitor-TiempoReal.ps1
# Monitor del sistema en tiempo real
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Log "Iniciando monitor en tiempo real" -Level "INFO"

# Función para obtener métricas
function Get-SystemMetrics {
    $os = Get-WmiObject Win32_OperatingSystem
    $cpu = Get-WmiObject Win32_Processor
    
    $metrics = @{
        CPUUsage = [math]::Round($cpu.LoadPercentage, 1)
        RAMTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        RAMUsedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
        RAMPercentage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        Timestamp = Get-Date -Format 'HH:mm:ss'
    }
    
    # Disco C:
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $metrics.DiskTotalGB = [math]::Round($disk.Size / 1GB, 2)
    $metrics.DiskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $metrics.DiskUsedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $metrics.DiskPercentage = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    
    # Red (velocidad aproximada)
    $netAdapters = Get-NetAdapterStatistics
    $totalBytesReceived = ($netAdapters | Measure-Object -Property ReceivedBytes -Sum).Sum
    $totalBytesSent = ($netAdapters | Measure-Object -Property SentBytes -Sum).Sum
    $metrics.NetworkReceivedMB = [math]::Round($totalBytesReceived / 1MB, 2)
    $metrics.NetworkSentMB = [math]::Round($totalBytesSent / 1MB, 2)
    
    # Procesos
    $metrics.ProcessCount = (Get-Process).Count
    
    return $metrics
}

# Función para dibujar barra de progreso
function Draw-ProgressBar {
    param(
        [double]$Percentage,
        [int]$Width = 30
    )
    
    $filled = [math]::Floor(($Percentage / 100) * $Width)
    $empty = $Width - $filled
    
    $color = "Green"
    if ($Percentage -gt 80) { $color = "Red" }
    elseif ($Percentage -gt 60) { $color = "Yellow" }
    
    $bar = "[" + ("█" * $filled) + (" " * $empty) + "]"
    Write-Host $bar -ForegroundColor $color -NoNewline
}

# Función para obtener top procesos
function Get-TopProcesses {
    param([int]$Count = 5)
    
    $processes = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First $Count
    return $processes
}

# Variables para velocidad de red
$lastReceivedBytes = 0
$lastSentBytes = 0
$lastCheckTime = Get-Date

Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MONITOR DEL SISTEMA EN TIEMPO REAL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Actualizando cada 2 segundos..." -ForegroundColor Gray
Write-Host "Presiona Ctrl+C para salir" -ForegroundColor Gray
Write-Host ""

$iteration = 0

while ($true) {
    $metrics = Get-SystemMetrics
    
    # Calcular velocidad de red (delta)
    $currentTime = Get-Date
    $timeDelta = ($currentTime - $lastCheckTime).TotalSeconds
    
    if ($timeDelta -gt 0 -and $lastReceivedBytes -gt 0) {
        $downloadSpeedMBps = [math]::Round((($metrics.NetworkReceivedMB * 1024 * 1024) - $lastReceivedBytes) / $timeDelta / 1024, 2)
        $uploadSpeedMBps = [math]::Round((($metrics.NetworkSentMB * 1024 * 1024) - $lastSentBytes) / $timeDelta / 1024, 2)
    } else {
        $downloadSpeedMBps = 0
        $uploadSpeedMBps = 0
    }
    
    $lastReceivedBytes = $metrics.NetworkReceivedMB * 1024 * 1024
    $lastSentBytes = $metrics.NetworkSentMB * 1024 * 1024
    $lastCheckTime = $currentTime
    
    # Mover cursor al inicio
    [Console]::SetCursorPosition(0, 8)
    
    # CPU
    Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host "💻 CPU: $($metrics.CPUUsage)%" -NoNewline -ForegroundColor White
    Write-Host (" " * (50 - "💻 CPU: $($metrics.CPUUsage)%".Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "│   " -NoNewline -ForegroundColor Cyan
    Draw-ProgressBar -Percentage $metrics.CPUUsage -Width 40
    Write-Host "                       │" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    
    # RAM
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host "💾 RAM: $($metrics.RAMUsedGB) GB / $($metrics.RAMTotalGB) GB ($($metrics.RAMPercentage)%)" -NoNewline -ForegroundColor White
    Write-Host (" " * (50 - "💾 RAM: $($metrics.RAMUsedGB) GB / $($metrics.RAMTotalGB) GB ($($metrics.RAMPercentage)%)".Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "│   " -NoNewline -ForegroundColor Cyan
    Draw-ProgressBar -Percentage $metrics.RAMPercentage -Width 40
    Write-Host "                       │" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    
    # Disco
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host "💽 Disco C: $($metrics.DiskUsedGB) GB / $($metrics.DiskTotalGB) GB ($($metrics.DiskPercentage)%)" -NoNewline -ForegroundColor White
    Write-Host (" " * (45 - "💽 Disco C: $($metrics.DiskUsedGB) GB / $($metrics.DiskTotalGB) GB ($($metrics.DiskPercentage)%)".Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "│   " -NoNewline -ForegroundColor Cyan
    Draw-ProgressBar -Percentage $metrics.DiskPercentage -Width 40
    Write-Host "                       │" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    
    # Red
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host "🌐 Red: ↓ $downloadSpeedMBps KB/s  ↑ $uploadSpeedMBps KB/s" -NoNewline -ForegroundColor White
    Write-Host (" " * (52 - "🌐 Red: ↓ $downloadSpeedMBps KB/s  ↑ $uploadSpeedMBps KB/s".Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    
    # Procesos
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host "📊 Procesos activos: $($metrics.ProcessCount)" -NoNewline -ForegroundColor White
    Write-Host (" " * (48 - "📊 Procesos activos: $($metrics.ProcessCount)".Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    
    # Top 5 procesos
    Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│ " -NoNewline -ForegroundColor Yellow
    Write-Host "🔥 TOP 5 PROCESOS (RAM)" -NoNewline -ForegroundColor White
    Write-Host (" " * 47) -NoNewline
    Write-Host "│" -ForegroundColor Yellow
    Write-Host "├────────────────────────────────────────────────────────────────────┤" -ForegroundColor Yellow
    
    $topProcesses = Get-TopProcesses -Count 5
    foreach ($proc in $topProcesses) {
        $ramMB = [math]::Round($proc.WorkingSet / 1MB, 0)
        $procName = $proc.ProcessName
        if ($procName.Length -gt 30) { $procName = $procName.Substring(0, 27) + "..." }
        
        $line = "│  $procName"
        $line += " " * (35 - $procName.Length)
        $line += "$ramMB MB"
        $line += " " * (35 - "$ramMB MB".Length)
        $line += "│"
        
        Write-Host $line -ForegroundColor Gray
    }
    
    Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    
    # Información adicional
    Write-Host "Última actualización: $($metrics.Timestamp) | Iteración: $iteration" -ForegroundColor DarkGray
    Write-Host ""
    
    $iteration++
    Start-Sleep -Seconds 2
}

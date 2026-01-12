<#
.SYNOPSIS
    Sistema de logging avanzado con rotación y niveles
.DESCRIPTION
    Maneja logs estructurados con diferentes niveles de severidad y rotación automática
.NOTES
    Versión: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1

# Niveles de log
enum LogLevel {
    TRACE = 0
    DEBUG = 1
    INFO = 2
    WARN = 3
    ERROR = 4
    FATAL = 5
}

$Global:LogPath = "$env:USERPROFILE\OptimizadorPC\logs"
$Global:LogFile = "$Global:LogPath\optimizador_$(Get-Date -Format 'yyyy-MM-dd').log"
$Global:CurrentLogLevel = [LogLevel]::INFO
$Global:MaxLogSizeMB = 10
$Global:MaxLogFiles = 5

function Initialize-Logger {
    <#
    .SYNOPSIS
        Inicializa el sistema de logging
    #>
    param(
        [LogLevel]$Level = [LogLevel]::INFO
    )
    
    $Global:CurrentLogLevel = $Level
    
    # Crear carpeta de logs
    if (-not (Test-Path $Global:LogPath)) {
        New-Item -Path $Global:LogPath -ItemType Directory -Force | Out-Null
    }
    
    # Verificar y rotar logs si es necesario
    Invoke-LogRotation
    
    Write-LogMessage -Level INFO -Message "Logger inicializado. Nivel: $Level"
}

function Write-LogMessage {
    <#
    .SYNOPSIS
        Escribe un mensaje en el log
    #>
    param(
        [Parameter(Mandatory=$true)]
        [LogLevel]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$Category = "General",
        
        [hashtable]$Data = @{}
    )
    
    # Verificar si el nivel es suficiente
    if ($Level -lt $Global:CurrentLogLevel) {
        return
    }
    
    # Construir mensaje estructurado
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $levelStr = $Level.ToString().PadRight(5)
    
    $logEntry = @{
        timestamp = $timestamp
        level = $levelStr
        category = $Category
        message = $Message
        data = $Data
        thread = [Threading.Thread]::CurrentThread.ManagedThreadId
        process = $PID
    }
    
    # Formato de salida
    $logLine = "$timestamp [$levelStr] [$Category] $Message"
    
    if ($Data.Count -gt 0) {
        $dataStr = ($Data.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
        $logLine += " | Data: $dataStr"
    }
    
    # Escribir a archivo
    try {
        Add-Content -Path $Global:LogFile -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Si falla, intentar escribir a un archivo de respaldo
        $backupLog = "$Global:LogPath\optimizador_backup.log"
        Add-Content -Path $backupLog -Value $logLine -Encoding UTF8
    }
    
    # Escribir a consola con colores
    $color = switch ($Level) {
        ([LogLevel]::TRACE) { "DarkGray" }
        ([LogLevel]::DEBUG) { "Gray" }
        ([LogLevel]::INFO)  { "White" }
        ([LogLevel]::WARN)  { "Yellow" }
        ([LogLevel]::ERROR) { "Red" }
        ([LogLevel]::FATAL) { "DarkRed" }
    }
    
    Write-Host $logLine -ForegroundColor $color
    
    # Verificar tamaño y rotar si es necesario
    Invoke-LogRotation
}

function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Rota los archivos de log cuando exceden el tamaño máximo
    #>
    
    if (-not (Test-Path $Global:LogFile)) {
        return
    }
    
    $logSize = (Get-Item $Global:LogFile).Length / 1MB
    
    if ($logSize -gt $Global:MaxLogSizeMB) {
        # Obtener archivos de log existentes
        $logFiles = Get-ChildItem -Path $Global:LogPath -Filter "optimizador_*.log" | 
                    Sort-Object LastWriteTime -Descending
        
        # Eliminar archivos antiguos si exceden el máximo
        if ($logFiles.Count -ge $Global:MaxLogFiles) {
            $logFiles | Select-Object -Skip ($Global:MaxLogFiles - 1) | Remove-Item -Force
        }
        
        # Rotar archivo actual
        $rotatedName = "optimizador_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
        Move-Item -Path $Global:LogFile -Destination "$Global:LogPath\$rotatedName" -Force
    }
}

function Write-LogTrace {
    param([string]$Message, [string]$Category = "General", [hashtable]$Data = @{})
    Write-LogMessage -Level TRACE -Message $Message -Category $Category -Data $Data
}

function Write-LogDebug {
    param([string]$Message, [string]$Category = "General", [hashtable]$Data = @{})
    Write-LogMessage -Level DEBUG -Message $Message -Category $Category -Data $Data
}

function Write-LogInfo {
    param([string]$Message, [string]$Category = "General", [hashtable]$Data = @{})
    Write-LogMessage -Level INFO -Message $Message -Category $Category -Data $Data
}

function Write-LogWarn {
    param([string]$Message, [string]$Category = "General", [hashtable]$Data = @{})
    Write-LogMessage -Level WARN -Message $Message -Category $Category -Data $Data
}

function Write-LogError {
    param([string]$Message, [string]$Category = "General", [hashtable]$Data = @{})
    Write-LogMessage -Level ERROR -Message $Message -Category $Category -Data $Data
}

function Write-LogFatal {
    param([string]$Message, [string]$Category = "General", [hashtable]$Data = @{})
    Write-LogMessage -Level FATAL -Message $Message -Category $Category -Data $Data
}

function Get-LogHistory {
    <#
    .SYNOPSIS
        Obtiene el historial de logs
    #>
    param(
        [int]$LastLines = 100,
        [LogLevel]$MinLevel = [LogLevel]::INFO
    )
    
    if (-not (Test-Path $Global:LogFile)) {
        Write-Host "⚠️  No hay logs disponibles" -ForegroundColor Yellow
        return
    }
    
    $logs = Get-Content -Path $Global:LogFile -Tail $LastLines
    
    # Filtrar por nivel
    $filteredLogs = $logs | Where-Object {
        $_ -match '\[(\w+)\]' -and 
        [LogLevel]::Parse([LogLevel], $Matches[1]) -ge $MinLevel
    }
    
    $filteredLogs | ForEach-Object { Write-Host $_ }
}

function Clear-Logs {
    <#
    .SYNOPSIS
        Limpia todos los archivos de log
    #>
    
    $confirmation = Read-Host "¿Eliminar todos los logs? (S/N)"
    
    if ($confirmation -eq "S" -or $confirmation -eq "s") {
        Get-ChildItem -Path $Global:LogPath -Filter "*.log" | Remove-Item -Force
        Write-Host "✅ Logs eliminados" -ForegroundColor Green
        Initialize-Logger
    }
}

function Export-LogsToJson {
    <#
    .SYNOPSIS
        Exporta logs a formato JSON
    #>
    param(
        [string]$OutputPath = "$Global:LogPath\export_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').json"
    )
    
    if (-not (Test-Path $Global:LogFile)) {
        Write-Host "⚠️  No hay logs para exportar" -ForegroundColor Yellow
        return
    }
    
    $logs = Get-Content -Path $Global:LogFile
    $jsonLogs = @()
    
    foreach ($log in $logs) {
        if ($log -match '^(\S+ \S+) \[(\w+)\] \[(\w+)\] (.+)') {
            $jsonLogs += @{
                timestamp = $Matches[1]
                level = $Matches[2].Trim()
                category = $Matches[3]
                message = $Matches[4]
            }
        }
    }
    
    $jsonLogs | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Logs exportados: $OutputPath" -ForegroundColor Green
}

# Inicializar logger al importar el módulo
Initialize-Logger

# Exportar funciones
Export-ModuleMember -Function Initialize-Logger, Write-LogMessage, Write-LogTrace, Write-LogDebug, `
                              Write-LogInfo, Write-LogWarn, Write-LogError, Write-LogFatal, `
                              Get-LogHistory, Clear-Logs, Export-LogsToJson

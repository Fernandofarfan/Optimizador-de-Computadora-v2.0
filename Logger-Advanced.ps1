<#
.SYNOPSIS
    Sistema de logging avanzado con rotacion y niveles
.DESCRIPTION
    Maneja logs estructurados con diferentes niveles de severidad y rotacion automatica
.NOTES
    Version: 4.0.0
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
        [Parameter(Mandatory=$true)][LogLevel]$Level,
        [Parameter(Mandatory=$true)][string]$Message,
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
    
    Write-Host "[$Category] $Message" -ForegroundColor $color
}

function Write-Log { param($Message, $Level = [LogLevel]::INFO) Write-LogMessage -Level $Level -Message $Message }
function Write-LogTrace { param($Message) Write-LogMessage -Level TRACE -Message $Message }
function Write-LogDebug { param($Message) Write-LogMessage -Level DEBUG -Message $Message }
function Write-LogInfo  { param($Message) Write-LogMessage -Level INFO -Message $Message }
function Write-LogWarn  { param($Message) Write-LogMessage -Level WARN -Message $Message }
function Write-LogError { param($Message) Write-LogMessage -Level ERROR -Message $Message }
function Write-LogFatal { param($Message) Write-LogMessage -Level FATAL -Message $Message }

function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Maneja la rotacion de archivos de log por tamano
    #>
    if (Test-Path $Global:LogFile) {
        $file = Get-Item $Global:LogFile
        if ($file.Length -gt ($Global:MaxLogSizeMB * 1MB)) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $archiveName = "$Global:LogPath\optimizador_$timestamp.log.bak"
            Move-Item -Path $Global:LogFile -Destination $archiveName -Force
            
            # Limpiar archivos antiguos
            $oldFiles = Get-ChildItem -Path $Global:LogPath -Filter "*.log.bak" | Sort-Object LastWriteTime -Descending
            if ($oldFiles.Count -gt $Global:MaxLogFiles) {
                $oldFiles | Select-Object -Skip $Global:MaxLogFiles | Remove-Item -Force
            }
        }
    }
}

function Get-LogHistory {
    <#
    .SYNOPSIS
        Obtiene los ultimos mensajes del log
    #>
    param([int]$Lines = 100)
    if (Test-Path $Global:LogFile) {
        return Get-Content -Path $Global:LogFile -Tail $Lines
    }
    return @()
}

function Clear-Logs {
    <#
    .SYNOPSIS
        Limpia todos los archivos de log
    #>
    if (Test-Path $Global:LogPath) {
        Remove-Item -Path "$Global:LogPath\*.log*" -Force
        Initialize-Logger
    }
}

function Export-LogsToJson {
    <#
    .SYNOPSIS
        Exporta logs actuales a formato JSON para analisis
    #>
    param([string]$OutputPath = "$PSScriptRoot\logs_export.json")
    $logs = Get-LogHistory -Lines 1000
    $structuredLogs = @()
    
    foreach ($line in $logs) {
        if ($line -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[(.*?)\] \[(.*?)\] (.*)$') {
            $structuredLogs += @{
                Timestamp = $matches[1]
                Level = $matches[2].Trim()
                Category = $matches[3]
                Message = $matches[4]
            }
        }
    }
    
    $structuredLogs | ConvertTo-Json | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Logs exportados: $OutputPath" -ForegroundColor Green
}

# Inicializar logger al importar el modulo
Initialize-Logger

# ============================================
# Logger.ps1 - Sistema de Logging Avanzado
# Manejo de logs con rotación automática y niveles de severidad
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Configuración del Logger
$global:LogConfig = @{
    LogDirectory = Join-Path $scriptPath "logs"
    MaxLogSizeMB = 5
    MaxLogFiles = 10
    DefaultLogLevel = "INFO"
    LogFilePrefix = "Optimizador"
    EnableConsole = $true
    EnableFile = $true
}

# Niveles de severidad con colores
$global:LogLevels = @{
    "DEBUG" = @{ Value = 0; Color = "Gray" }
    "INFO" = @{ Value = 1; Color = "Cyan" }
    "SUCCESS" = @{ Value = 2; Color = "Green" }
    "WARNING" = @{ Value = 3; Color = "Yellow" }
    "ERROR" = @{ Value = 4; Color = "Red" }
    "CRITICAL" = @{ Value = 5; Color = "Magenta" }
}

# ============================================
# Funciones del Logger
# ============================================

function Initialize-Logger {
    <#
    .SYNOPSIS
    Inicializa el sistema de logging creando directorios y archivo de log
    #>
    
    # Crear directorio de logs si no existe
    if (-not (Test-Path $LogConfig.LogDirectory)) {
        New-Item -ItemType Directory -Path $LogConfig.LogDirectory -Force | Out-Null
    }
    
    # Generar nombre de archivo con timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    $logFileName = "$($LogConfig.LogFilePrefix)_$timestamp.log"
    $global:CurrentLogFile = Join-Path $LogConfig.LogDirectory $logFileName
    
    # Rotar logs si es necesario
    Rotate-Logs
    
    # Escribir encabezado
    $header = @"
========================================
OPTIMIZADOR DE COMPUTADORA - LOG
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Usuario: $env:USERNAME
Computadora: $env:COMPUTERNAME
========================================

"@
    
    if ($LogConfig.EnableFile) {
        Add-Content -Path $CurrentLogFile -Value $header -Encoding UTF8
    }
}

function Write-Log {
    <#
    .SYNOPSIS
    Escribe un mensaje en el log con nivel de severidad
    
    .PARAMETER Message
    Mensaje a escribir
    
    .PARAMETER Level
    Nivel de severidad (DEBUG, INFO, SUCCESS, WARNING, ERROR, CRITICAL)
    
    .PARAMETER NoConsole
    No mostrar en consola, solo escribir en archivo
    
    .EXAMPLE
    Write-Log "Sistema analizado correctamente" -Level "SUCCESS"
    Write-Log "Error al detener servicio" -Level "ERROR"
    #>
    
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("DEBUG", "INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL")]
        [string]$Level = "INFO",
        
        [switch]$NoConsole
    )
    
    # Verificar si el nivel está habilitado
    $currentLevelValue = $LogLevels[$LogConfig.DefaultLogLevel].Value
    $messageLevelValue = $LogLevels[$Level].Value
    
    if ($messageLevelValue -lt $currentLevelValue) {
        return
    }
    
    # Formatear mensaje
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Escribir en archivo
    if ($LogConfig.EnableFile -and $CurrentLogFile) {
        Add-Content -Path $CurrentLogFile -Value $logEntry -Encoding UTF8
    }
    
    # Escribir en consola
    if ($LogConfig.EnableConsole -and -not $NoConsole) {
        $color = $LogLevels[$Level].Color
        
        # Formatear para consola
        $consoleMessage = "[$Level] $Message"
        Write-Host $consoleMessage -ForegroundColor $color
    }
}

function Rotate-Logs {
    <#
    .SYNOPSIS
    Rota los archivos de log eliminando los más antiguos si exceden límites
    #>
    
    if (-not (Test-Path $LogConfig.LogDirectory)) {
        return
    }
    
    # Obtener todos los archivos de log
    $logFiles = Get-ChildItem -Path $LogConfig.LogDirectory -Filter "$($LogConfig.LogFilePrefix)_*.log" |
                Sort-Object LastWriteTime -Descending
    
    # Eliminar logs que exceden el tamaño máximo
    foreach ($logFile in $logFiles) {
        $sizeMB = ($logFile.Length / 1MB)
        if ($sizeMB -gt $LogConfig.MaxLogSizeMB) {
            Remove-Item -Path $logFile.FullName -Force
            Write-Log "Log rotado por tamaño: $($logFile.Name)" -Level "INFO"
        }
    }
    
    # Eliminar logs excedentes (mantener solo MaxLogFiles)
    $logFiles = Get-ChildItem -Path $LogConfig.LogDirectory -Filter "$($LogConfig.LogFilePrefix)_*.log" |
                Sort-Object LastWriteTime -Descending
    
    if ($logFiles.Count -gt $LogConfig.MaxLogFiles) {
        $filesToDelete = $logFiles | Select-Object -Skip $LogConfig.MaxLogFiles
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file.FullName -Force
            Write-Log "Log antiguo eliminado: $($file.Name)" -Level "INFO"
        }
    }
}

function Get-LogStats {
    <#
    .SYNOPSIS
    Obtiene estadísticas de los logs
    #>
    
    Write-Host "`nEstadísticas de Logs:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if (-not (Test-Path $LogConfig.LogDirectory)) {
        Write-Host "No hay logs disponibles" -ForegroundColor Yellow
        return
    }
    
    $logFiles = Get-ChildItem -Path $LogConfig.LogDirectory -Filter "$($LogConfig.LogFilePrefix)_*.log"
    
    $totalSize = ($logFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    $totalCount = $logFiles.Count
    
    Write-Host "Total de archivos: $totalCount" -ForegroundColor White
    Write-Host "Tamaño total: $([math]::Round($totalSize, 2)) MB" -ForegroundColor White
    Write-Host "Directorio: $($LogConfig.LogDirectory)" -ForegroundColor White
    
    if ($logFiles.Count -gt 0) {
        Write-Host "`nÚltimos 5 logs:" -ForegroundColor Cyan
        $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
            $sizeMB = [math]::Round(($_.Length / 1MB), 2)
            Write-Host "  $($_.Name) - $sizeMB MB - $($_.LastWriteTime)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nLog actual: $CurrentLogFile" -ForegroundColor Green
}

function Set-LogLevel {
    <#
    .SYNOPSIS
    Cambia el nivel de logging
    
    .PARAMETER Level
    Nuevo nivel (DEBUG, INFO, SUCCESS, WARNING, ERROR, CRITICAL)
    #>
    
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("DEBUG", "INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL")]
        [string]$Level
    )
    
    $LogConfig.DefaultLogLevel = $Level
    Write-Log "Nivel de log cambiado a: $Level" -Level "INFO"
}

function Export-LogReport {
    <#
    .SYNOPSIS
    Exporta un reporte resumido de errores y warnings del log actual
    #>
    
    if (-not $CurrentLogFile -or -not (Test-Path $CurrentLogFile)) {
        Write-Host "No hay log actual disponible" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nGenerando reporte de errores y advertencias..." -ForegroundColor Cyan
    
    $content = Get-Content -Path $CurrentLogFile
    $errors = $content | Where-Object { $_ -match '\[ERROR\]|\[CRITICAL\]' }
    $warnings = $content | Where-Object { $_ -match '\[WARNING\]' }
    
    $reportPath = Join-Path $LogConfig.LogDirectory "Reporte-Errores-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
    
    $report = @"
========================================
REPORTE DE ERRORES Y ADVERTENCIAS
Generado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Log fuente: $(Split-Path $CurrentLogFile -Leaf)
========================================

ERRORES CRÍTICOS ($($errors.Count)):
----------------------------------------
$($errors -join "`n")

ADVERTENCIAS ($($warnings.Count)):
----------------------------------------
$($warnings -join "`n")

========================================
"@
    
    Set-Content -Path $reportPath -Value $report -Encoding UTF8
    
    Write-Host "`nReporte generado:" -ForegroundColor Green
    Write-Host "  $reportPath" -ForegroundColor White
    Write-Host "  Errores: $($errors.Count)" -ForegroundColor Red
    Write-Host "  Advertencias: $($warnings.Count)" -ForegroundColor Yellow
}

# ============================================
# Ejemplos de Uso
# ============================================

function Test-Logger {
    <#
    .SYNOPSIS
    Función de prueba para demostrar el logger
    #>
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PRUEBA DEL SISTEMA DE LOGGING" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Initialize-Logger
    
    Write-Log "Iniciando análisis del sistema" -Level "INFO"
    Write-Log "Detectando servicios innecesarios" -Level "DEBUG"
    Write-Log "Servicio DiagTrack deshabilitado exitosamente" -Level "SUCCESS"
    Write-Log "Servicio SysMain no encontrado" -Level "WARNING"
    Write-Log "Error al detener servicio WSearch: Acceso denegado" -Level "ERROR"
    Write-Log "FALLO CRÍTICO: No se puede acceder al registro" -Level "CRITICAL"
    
    Write-Host ""
    Get-LogStats
    
    Write-Host "`n¿Desea generar reporte de errores? (S/N): " -NoNewline
    $response = Read-Host
    if ($response -eq "S" -or $response -eq "s") {
        Export-LogReport
    }
}

# Exportar funciones para uso en otros scripts
Export-ModuleMember -Function Initialize-Logger, Write-Log, Rotate-Logs, Get-LogStats, Set-LogLevel, Export-LogReport

# Si se ejecuta directamente, mostrar prueba
if ($MyInvocation.InvocationName -ne '.') {
    Test-Logger
}

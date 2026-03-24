<#
.SYNOPSIS
    Notifications-Manager.ps1 - Wrapper for notification systems and resource monitoring helpers
.DESCRIPTION
    Este modulo sirve como puente entre los sistemas de notificaciones existentes
    y proporciona funciones de monitoreo de recursos para la suite de tests.
.VERSION
    4.0.0
#>

# Forzar codificacion UTF-8 para evitar problemas de consola
if ($PSVersionTable.PSVersion.Major -ge 5) {
    $OutputEncoding = [System.Text.Encoding]::UTF8
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Cargar dependencias
$toastPath = Join-Path $scriptPath "Toast-Notifications.ps1"
$smartPath = Join-Path $scriptPath "Notificaciones-Inteligentes.ps1"

if (Test-Path $toastPath) { . $toastPath }
if (Test-Path $smartPath) { . $smartPath }

# --- Mapeo de Funciones para Test Suite ---

function Send-CriticalNotification {
    <#
    .SYNOPSIS
        Envia una notificacion critica
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Message
    )
    if (Get-Command "Show-ErrorNotification" -ErrorAction SilentlyContinue) {
        Show-ErrorNotification -Title $Title -Message $Message
    }
    elseif (Get-Command "Show-CriticalAlert" -ErrorAction SilentlyContinue) {
        Show-CriticalAlert -Title $Title -Message $Message -Severity "CRITICAL"
    }
}

function Send-WarningNotification {
    <#
    .SYNOPSIS
        Envia una notificacion de advertencia
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Message
    )
    if (Get-Command "Show-WarningNotification" -ErrorAction SilentlyContinue) {
        Show-WarningNotification -Title $Title -Message $Message
    }
    elseif (Get-Command "Show-CriticalAlert" -ErrorAction SilentlyContinue) {
        Show-CriticalAlert -Title $Title -Message $Message -Severity "WARNING"
    }
}

function Send-InfoNotification {
    <#
    .SYNOPSIS
        Envia una notificacion informativa
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Message
    )
    if (Get-Command "Show-InfoNotification" -ErrorAction SilentlyContinue) {
        Show-InfoNotification -Title $Title -Message $Message
    }
    elseif (Get-Command "Show-CriticalAlert" -ErrorAction SilentlyContinue) {
        Show-CriticalAlert -Title $Title -Message $Message -Severity "INFO"
    }
}

# --- Helpers de Monitoreo de Recursos ---

function Get-RAMUsage {
    <#
    .SYNOPSIS
        Obtiene el porcentaje de uso de RAM
    #>
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $usage = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100)
        return $usage
    } catch {
        return 0
    }
}

function Get-DiskUsage {
    <#
    .SYNOPSIS
        Obtiene el porcentaje de uso de disco
    #>
    param([string]$Drive = "C:")
    try {
        $disk = Get-PSDrive $Drive.Replace(":", "") -ErrorAction Stop
        $usage = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100)
        return $usage
    } catch {
        return 0
    }
}

function Get-CPUUsage {
    <#
    .SYNOPSIS
        Obtiene el porcentaje de uso de CPU
    #>
    try {
        $cpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -ErrorAction SilentlyContinue | 
               Where-Object { $_.Name -eq "_Total" } | Select-Object -First 1
        if ($null -eq $cpu) { return 0 }
        return [math]::Round($cpu.PercentProcessorTime)
    } catch {
        return 0
    }
}

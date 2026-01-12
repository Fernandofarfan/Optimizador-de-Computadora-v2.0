# ============================================
# UI-Enhancements.ps1 - Mejoras de Interfaz de Usuario
# Barras de progreso, confirmaciones, y mejor UX
# Versión: 4.0.0
# ============================================

$ErrorActionPreference = 'SilentlyContinue'

# ============================================
# Función: Mostrar barra de progreso
# ============================================
function Show-ProgressBar {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Activity,
        
        [Parameter(Mandatory=$true)]
        [int]$Total,
        
        [string]$Status = "Procesando...",
        [int]$Current = 0
    )
    
    $percent = [int](($Current / $Total) * 100)
    $filled = [int]($percent / 5)
    $empty = 20 - $filled
    
    $bar = "█" * $filled + "░" * $empty
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $percent -CurrentOperation "[$bar] $percent%"
}

# ============================================
# Función: Mostrar animación de carga
# ============================================
function Show-LoadingAnimation {
    param(
        [string]$Message = "Procesando",
        [int]$Duration = 3
    )
    
    $frames = @('|', '/', '-', '\')
    $startTime = Get-Date
    
    while ((Get-Date) - $startTime | Select-Object -ExpandProperty TotalSeconds | ForEach-Object { $_ -lt $Duration }) {
        foreach ($frame in $frames) {
            Write-Host "`r$frame $Message" -NoNewline
            Start-Sleep -Milliseconds 100
        }
    }
    Write-Host "`r✅ Completado" -ForegroundColor Green
}

# ============================================
# Función: Solicitar confirmación
# ============================================
function Get-UserConfirmation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$DefaultAnswer = "N"
    )
    
    $validAnswers = @('S', 'Y', 's', 'y', 'N', 'n')
    
    while ($true) {
        Write-Host ""
        Write-Host "⚠️  $Message" -ForegroundColor Yellow
        Write-Host "Escribe [S]í o [N]o (Default: $DefaultAnswer):" -ForegroundColor Gray
        
        $response = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $DefaultAnswer -eq "S" -or $DefaultAnswer -eq "Y"
        }
        
        if ($validAnswers -contains $response) {
            return $response -eq "S" -or $response -eq "Y" -or $response -eq "y" -or $response -eq "s"
        }
        
        Write-Host "Respuesta no válida. Intenta de nuevo." -ForegroundColor Red
    }
}

# ============================================
# Función: Mostrar menú mejorado
# ============================================
function Show-EnhancedMenu {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Options,
        
        [string]$Title = "MENÚ",
        [string]$Description = ""
    )
    
    Clear-Host
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if ($Description) {
        Write-Host "  $Description" -ForegroundColor Gray
        Write-Host ""
    }
    
    foreach ($key in $Options.Keys | Sort-Object) {
        if ($key -eq "0") {
            Write-Host "  [$key] $($Options[$key])" -ForegroundColor Gray
        } else {
            Write-Host "  [$key] $($Options[$key])" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    while ($true) {
        $choice = Read-Host "  Selecciona una opción"
        
        if ($Options.ContainsKey($choice)) {
            return $choice
        }
        
        Write-Host "  ❌ Opción no válida. Intenta de nuevo." -ForegroundColor Red
    }
}

# ============================================
# Función: Mostrar notificación
# ============================================
function Show-Notification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Type = "INFO"
    )
    
    $icon = switch ($Type) {
        "SUCCESS" { "✅" }
        "WARNING" { "⚠️" }
        "ERROR" { "❌" }
        default { "ℹ️" }
    }
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    
    Write-Host ""
    Write-Host "  $icon $Message" -ForegroundColor $color
    Write-Host ""
}

# ============================================
# Función: Mostrar resultado de operación
# ============================================
function Show-OperationResult {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [Parameter(Mandatory=$true)]
        [bool]$Success,
        
        [string]$Message = "",
        [int]$Duration = 0
    )
    
    Write-Host ""
    Write-Host "┌──────────────────────────────────────────┐" -ForegroundColor Gray
    
    if ($Success) {
        Write-Host "│  ✅ OPERACIÓN COMPLETADA                 │" -ForegroundColor Green
        Write-Host "│                                          │" -ForegroundColor Green
        Write-Host "│  $Operation" -ForegroundColor Green
    } else {
        Write-Host "│  ❌ OPERACIÓN FALLIDA                    │" -ForegroundColor Red
        Write-Host "│                                          │" -ForegroundColor Red
        Write-Host "│  $Operation" -ForegroundColor Red
    }
    
    if ($Message) {
        Write-Host "│  Detalles: $Message" -ForegroundColor Gray
    }
    
    if ($Duration -gt 0) {
        Write-Host "│  Duración: $Duration segundos" -ForegroundColor Gray
    }
    
    Write-Host "└──────────────────────────────────────────┘" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# Función: Mostrar tabla formateada
# ============================================
function Show-FormattedTable {
    param(
        [Parameter(Mandatory=$true)]
        [object[]]$Items,
        
        [string]$Title = "",
        [string[]]$Properties
    )
    
    if ($Title) {
        Write-Host ""
        Write-Host "┌─ $Title" -ForegroundColor Cyan
    }
    
    if ($Properties) {
        $Items | Format-Table -Property $Properties -AutoSize
    } else {
        $Items | Format-Table -AutoSize
    }
    
    Write-Host ""
}

# ============================================
# Función: Mostrar spinner mientras se procesa
# ============================================
function Invoke-WithSpinner {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [string]$Message = "Procesando..."
    )
    
    $job = Start-Job -ScriptBlock {
        param($script)
        & $script
    } -ArgumentList $ScriptBlock
    
    $frames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $frameIndex = 0
    
    while ($job.State -eq "Running") {
        Write-Host "`r$($frames[$frameIndex % $frames.Length]) $Message" -NoNewline
        $frameIndex++
        Start-Sleep -Milliseconds 80
    }
    
    $result = Receive-Job -Job $job
    Write-Host "`r✅ $Message" -ForegroundColor Green
    
    Remove-Job -Job $job
    
    return $result
}

# ============================================
# Función: Solicitar entrada validada
# ============================================
function Get-ValidatedInput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [scriptblock]$ValidationScript = { $args[0] -ne "" },
        [string]$ErrorMessage = "Entrada inválida"
    )
    
    while ($true) {
        $input = Read-Host $Prompt
        
        if (& $ValidationScript $input) {
            return $input
        }
        
        Write-Host "  ❌ $ErrorMessage" -ForegroundColor Red
    }
}

# ============================================
# Función: Mostrar barra de estado
# ============================================
function Show-StatusBar {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "PROCESSING")]
        [string]$Status = "INFO"
    )
    
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "PROCESSING" { "Cyan" }
        default { "White" }
    }
    
    Write-Host ""
    Write-Host "═" * 70 -ForegroundColor $color
    Write-Host "  $Text" -ForegroundColor $color
    Write-Host "═" * 70 -ForegroundColor $color
    Write-Host ""
}

# ============================================
# Función: Mostrar encabezado de sección
# ============================================
function Show-SectionHeader {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [string]$Icon = "▶"
    )
    
    Write-Host ""
    Write-Host "  $Icon $Title" -ForegroundColor Cyan
    Write-Host "  $(('-' * ($Title.Length + $Icon.Length + 1)))" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# Función: Mostrar advertencia importante
# ============================================
function Show-ImportantWarning {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host ""
    Write-Host "╔" + ("═" * 68) + "╗" -ForegroundColor Red
    Write-Host "║  ⚠️  ADVERTENCIA IMPORTANTE" + (" " * 42) + "║" -ForegroundColor Red
    Write-Host "╠" + ("═" * 68) + "╣" -ForegroundColor Red
    
    $lines = $Message -split "`n"
    foreach ($line in $lines) {
        $padding = 68 - $line.Length
        Write-Host "║  $line" + (" " * $padding) + "║" -ForegroundColor Red
    }
    
    Write-Host "╚" + ("═" * 68) + "╝" -ForegroundColor Red
    Write-Host ""
}

# ============================================
# Función: Mostrar caja de información
# ============================================
function Show-InfoBox {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Content
    )
    
    Write-Host ""
    Write-Host "┌─ $Title" -ForegroundColor Cyan
    
    foreach ($line in $Content) {
        Write-Host "│  $line" -ForegroundColor Gray
    }
    
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================
# Exportar funciones
# ============================================

Export-ModuleMember -Function @(
    'Show-ProgressBar',
    'Show-LoadingAnimation',
    'Get-UserConfirmation',
    'Show-EnhancedMenu',
    'Show-Notification',
    'Show-OperationResult',
    'Show-FormattedTable',
    'Invoke-WithSpinner',
    'Get-ValidatedInput',
    'Show-StatusBar',
    'Show-SectionHeader',
    'Show-ImportantWarning',
    'Show-InfoBox'
)

# ============================================
# Operations-History.ps1 - Sistema de Historial de Operaciones
# Registra y gestiona el historial de optimizaciones
# Versión: 4.0.0
# ============================================

using namespace System
using namespace System.Collections.Generic

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ============================================
# Configuración
# ============================================

$historyPath = "$env:USERPROFILE\OptimizadorPC\history"
$historyFile = Join-Path $historyPath "operations.json"
$maxHistoryEntries = 1000

# ============================================
# Función: Obtener historial de operaciones
# ============================================
function Get-OperationHistory {
    param(
        [int]$Last = 50,
        [string]$Filter = ""
    )
    
    if (-not (Test-Path $historyFile)) {
        return @()
    }
    
    try {
        $history = Get-Content -Path $historyFile -Raw | ConvertFrom-Json -ErrorAction Stop
        
        if ($Filter) {
            $history = $history | Where-Object { $_.operation -like "*$Filter*" -or $_.status -like "*$Filter*" }
        }
        
        return $history | Sort-Object -Property timestamp -Descending | Select-Object -First $Last
    }
    catch {
        Write-Host "Error al leer historial: $_" -ForegroundColor Red
        return @()
    }
}

# ============================================
# Función: Agregar operación al historial
# ============================================
function Add-OperationRecord {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [Parameter(Mandatory=$true)]
        [string]$Status,
        
        [string]$Description = "",
        [string]$Details = "",
        [int]$Duration = 0,
        [string]$ErrorMessage = ""
    )
    
    # Crear directorio si no existe
    if (-not (Test-Path $historyPath)) {
        New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
    }
    
    # Crear nueva entrada
    $entry = @{
        id = [guid]::NewGuid().ToString()
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        operation = $Operation
        status = $Status
        description = $Description
        details = $Details
        duration_seconds = $Duration
        error_message = $ErrorMessage
        username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        machine = $env:COMPUTERNAME
    }
    
    # Leer historial existente
    $history = @()
    if (Test-Path $historyFile) {
        try {
            $history = @(Get-Content -Path $historyFile -Raw | ConvertFrom-Json -ErrorAction Stop)
        }
        catch {
            $history = @()
        }
    }
    
    # Agregar nueva entrada
    $history += $entry
    
    # Limitar a máximo de entradas
    if ($history.Count -gt $maxHistoryEntries) {
        $history = $history | Select-Object -Last $maxHistoryEntries
    }
    
    # Guardar historial
    try {
        $history | ConvertTo-Json -Depth 10 | Set-Content -Path $historyFile -Force -Encoding UTF8
        return $true
    }
    catch {
        Write-Host "Error al guardar operación: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================
# Función: Mostrar historial con formato
# ============================================
function Show-OperationHistory {
    param(
        [int]$Last = 20
    )
    
    $history = Get-OperationHistory -Last $Last
    
    if ($history.Count -eq 0) {
        Write-Host "No hay historial de operaciones" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           HISTORIAL DE OPERACIONES - ÚLTIMAS $Last OPERACIONES              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($entry in $history) {
        $statusColor = switch ($entry.status) {
            "SUCCESS" { "Green" }
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "PENDING" { "Cyan" }
            default { "White" }
        }
        
        Write-Host "┌─ [$($entry.timestamp)]" -ForegroundColor Gray
        Write-Host "│  Operación: $($entry.operation)" -ForegroundColor White
        Write-Host "│  Estado: $($entry.status)" -ForegroundColor $statusColor
        
        if ($entry.description) {
            Write-Host "│  Descripción: $($entry.description)" -ForegroundColor White
        }
        
        if ($entry.duration_seconds -gt 0) {
            Write-Host "│  Duración: $($entry.duration_seconds) segundos" -ForegroundColor Gray
        }
        
        if ($entry.error_message) {
            Write-Host "│  Error: $($entry.error_message)" -ForegroundColor Red
        }
        
        Write-Host "└─" -ForegroundColor Gray
        Write-Host ""
    }
}

# ============================================
# Función: Generar reporte en HTML
# ============================================
function Export-OperationHistoryHTML {
    param(
        [int]$Days = 30,
        [string]$OutputPath = "$env:USERPROFILE\OptimizadorPC\operation-report.html"
    )
    
    $history = Get-OperationHistory -Last 1000
    $dateFilter = (Get-Date).AddDays(-$Days)
    
    # Filtrar por fecha
    $filtered = @()
    foreach ($entry in $history) {
        if ([datetime]::ParseExact($entry.timestamp, "yyyy-MM-dd HH:mm:ss", $null) -gt $dateFilter) {
            $filtered += $entry
        }
    }
    
    # Estadísticas
    $totalOps = $filtered.Count
    $successOps = ($filtered | Where-Object { $_.status -eq "SUCCESS" }).Count
    $errorOps = ($filtered | Where-Object { $_.status -eq "ERROR" }).Count
    $avgDuration = [int]($filtered | Measure-Object -Property duration_seconds -Average).Average
    
    # HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reporte de Operaciones - Optimizador PC v4.0</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 20px; color: #333; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 20px; }
        .stat-box { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-label { font-size: 12px; color: #666; text-transform: uppercase; }
        .stat-value { font-size: 28px; font-weight: bold; margin: 5px 0 0 0; }
        .success { color: #10b981; }
        .error { color: #ef4444; }
        .warning { color: #f59e0b; }
        .pending { color: #3b82f6; }
        table { width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 12px; border-bottom: 1px solid #e5e7eb; }
        tr:hover { background: #f9fafb; }
        .timestamp { font-size: 12px; color: #666; }
        .operation { font-weight: 600; }
        .status-badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600; }
        .status-success { background: #d1fae5; color: #065f46; }
        .status-error { background: #fee2e2; color: #7f1d1d; }
        .status-warning { background: #fef3c7; color: #92400e; }
        .status-pending { background: #dbeafe; color: #1e40af; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Reporte de Operaciones</h1>
        <p>Optimizador PC v4.0 - Últimos $Days días</p>
        <p style="margin: 10px 0 0 0; font-size: 12px;">Generado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="stats">
        <div class="stat-box">
            <div class="stat-label">Total de Operaciones</div>
            <div class="stat-value">$totalOps</div>
        </div>
        <div class="stat-box">
            <div class="stat-label">Operaciones Exitosas</div>
            <div class="stat-value success">$successOps</div>
        </div>
        <div class="stat-box">
            <div class="stat-label">Errores</div>
            <div class="stat-value error">$errorOps</div>
        </div>
        <div class="stat-box">
            <div class="stat-label">Duración Promedio</div>
            <div class="stat-value">$($avgDuration)s</div>
        </div>
    </div>
    
    <h2>Historial Detallado</h2>
    <table>
        <thead>
            <tr>
                <th>Fecha/Hora</th>
                <th>Operación</th>
                <th>Estado</th>
                <th>Descripción</th>
                <th>Duración</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($entry in $filtered) {
        $statusClass = "status-$($entry.status.ToLower())"
        $html += @"
            <tr>
                <td class="timestamp">$($entry.timestamp)</td>
                <td class="operation">$($entry.operation)</td>
                <td><span class="status-badge $statusClass">$($entry.status)</span></td>
                <td>$($entry.description)</td>
                <td>$($entry.duration_seconds)s</td>
            </tr>
"@
    }
    
    $html += @"
        </tbody>
    </table>
    
    <div class="footer">
        <p>Este reporte fue generado automáticamente por Optimizador PC v4.0</p>
        <p>Para más información, visita: https://fernandofarfan.github.io/Optimizador-de-Computadora/</p>
    </div>
</body>
</html>
"@
    
    try {
        $html | Set-Content -Path $OutputPath -Encoding UTF8 -Force
        Write-Host "✅ Reporte HTML generado: $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Error al generar reporte: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================
# Función: Limpiar historial antiguo
# ============================================
function Clear-OldOperationHistory {
    param(
        [int]$DaysToKeep = 90
    )
    
    if (-not (Test-Path $historyFile)) {
        Write-Host "No hay historial que limpiar" -ForegroundColor Yellow
        return
    }
    
    $history = Get-OperationHistory -Last 10000
    $dateFilter = (Get-Date).AddDays(-$DaysToKeep)
    
    $filtered = @()
    foreach ($entry in $history) {
        if ([datetime]::ParseExact($entry.timestamp, "yyyy-MM-dd HH:mm:ss", $null) -gt $dateFilter) {
            $filtered += $entry
        }
    }
    
    try {
        $filtered | ConvertTo-Json -Depth 10 | Set-Content -Path $historyFile -Force -Encoding UTF8
        Write-Host "✅ Historial limpiado. Entries mantenidas: $($filtered.Count)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Error al limpiar historial: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================
# Menú Principal si se ejecuta directamente
# ============================================

if ($MyInvocation.InvocationName -eq "." -or $MyInvocation.InvocationName -eq $null) {
    # Importado como módulo
    exit
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    SISTEMA DE HISTORIAL DE OPERACIONES v4.0   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Ver historial completo" -ForegroundColor White
Write-Host "2. Exportar reporte HTML (últimos 30 días)" -ForegroundColor White
Write-Host "3. Limpiar historial antiguo (> 90 días)" -ForegroundColor White
Write-Host "4. Ver estadísticas" -ForegroundColor White
Write-Host "0. Salir" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Selecciona una opción"

switch ($choice) {
    '1' {
        Show-OperationHistory -Last 50
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
    }
    '2' {
        $outputPath = "$env:USERPROFILE\OptimizadorPC\operaciones-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
        Export-OperationHistoryHTML -Days 30 -OutputPath $outputPath
        Write-Host ""
        Write-Host "¿Deseas abrir el reporte? (S/N)" -ForegroundColor Yellow
        if ((Read-Host) -eq "S") {
            Start-Process $outputPath
        }
    }
    '3' {
        $confirm = Read-Host "¿Estás seguro de que deseas eliminar operaciones > 90 días? (S/N)"
        if ($confirm -eq "S") {
            Clear-OldOperationHistory -DaysToKeep 90
        }
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
    }
    '4' {
        $history = Get-OperationHistory -Last 1000
        $success = ($history | Where-Object { $_.status -eq "SUCCESS" }).Count
        $errors = ($history | Where-Object { $_.status -eq "ERROR" }).Count
        $warnings = ($history | Where-Object { $_.status -eq "WARNING" }).Count
        
        Write-Host ""
        Write-Host "📊 ESTADÍSTICAS DEL HISTORIAL" -ForegroundColor Cyan
        Write-Host "  Total de operaciones: $($history.Count)" -ForegroundColor White
        Write-Host "  ✅ Exitosas: $success" -ForegroundColor Green
        Write-Host "  ❌ Con errores: $errors" -ForegroundColor Red
        Write-Host "  ⚠️  Advertencias: $warnings" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
    }
    '0' { exit }
    default { Write-Host "Opción no válida" -ForegroundColor Red }
}

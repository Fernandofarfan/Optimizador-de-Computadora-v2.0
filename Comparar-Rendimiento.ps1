# ============================================
# Comparar-Rendimiento.ps1
# Comparación de rendimiento antes/después
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COMPARADOR DE RENDIMIENTO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$snapshotPath = "$scriptPath\snapshot.json"

# Función para tomar snapshot
function Get-SystemSnapshot {
    $snapshot = @{
        Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        CPU = (Get-WmiObject Win32_Processor).LoadPercentage
        RAMUsadaPorcentaje = [math]::Round(((Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize - (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory) / (Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize * 100, 1)
        RAMLibreMB = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1024, 0)
        DiscoLibreGB = [math]::Round((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)
        ServiciosEnEjecucion = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
        ProgramasInicio = (Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Count
        Procesos = (Get-Process).Count
    }
    return $snapshot
}

# Menú
Write-Host "Opciones disponibles:" -ForegroundColor White
Write-Host "  [1] Guardar snapshot ANTES de optimizar" -ForegroundColor Green
Write-Host "  [2] Comparar con snapshot anterior (DESPUÉS)" -ForegroundColor Cyan
Write-Host "  [3] Ver snapshot guardado" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona opción"

switch ($opcion) {
    '1' {
        Write-Host ""
        Write-Host "📸 Capturando estado actual del sistema..." -ForegroundColor Cyan
        $snapshot = Get-SystemSnapshot
        $snapshot | ConvertTo-Json | Out-File $snapshotPath -Encoding UTF8
        
        Write-Host "✅ Snapshot guardado exitosamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "Estado actual:" -ForegroundColor Yellow
        Write-Host "  • CPU: $($snapshot.CPU)%" -ForegroundColor White
        Write-Host "  • RAM usada: $($snapshot.RAMUsadaPorcentaje)%" -ForegroundColor White
        Write-Host "  • Disco libre: $($snapshot.DiscoLibreGB) GB" -ForegroundColor White
        Write-Host "  • Servicios ejecutándose: $($snapshot.ServiciosEnEjecucion)" -ForegroundColor White
        Write-Host "  • Programas en inicio: $($snapshot.ProgramasInicio)" -ForegroundColor White
        Write-Host "  • Procesos: $($snapshot.Procesos)" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Ahora ejecuta las optimizaciones y luego usa opción [2]" -ForegroundColor Cyan
        Write-Log "Snapshot ANTES guardado" -Level "SUCCESS"
    }
    '2' {
        if (-not (Test-Path $snapshotPath)) {
            Write-Host "❌ No hay snapshot anterior. Primero usa opción [1]" -ForegroundColor Red
            break
        }
        
        Write-Host ""
        Write-Host "📸 Capturando estado actual y comparando..." -ForegroundColor Cyan
        Write-Host ""
        
        $antes = Get-Content $snapshotPath | ConvertFrom-Json
        $despues = Get-SystemSnapshot
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "COMPARACIÓN DE RENDIMIENTO" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # CPU
        $diffCPU = $despues.CPU - $antes.CPU
        $colorCPU = if ($diffCPU -le 0) { "Green" } else { "Red" }
        Write-Host "CPU:" -ForegroundColor Yellow
        Write-Host "  Antes:  $($antes.CPU)%" -ForegroundColor White
        Write-Host "  Después: $($despues.CPU)%" -ForegroundColor White
        Write-Host "  Cambio: $(if ($diffCPU -gt 0) { '+' })$diffCPU%" -ForegroundColor $colorCPU
        Write-Host ""
        
        # RAM
        $diffRAM = $despues.RAMUsadaPorcentaje - $antes.RAMUsadaPorcentaje
        $colorRAM = if ($diffRAM -le 0) { "Green" } else { "Red" }
        Write-Host "RAM Usada:" -ForegroundColor Yellow
        Write-Host "  Antes:  $($antes.RAMUsadaPorcentaje)%" -ForegroundColor White
        Write-Host "  Después: $($despues.RAMUsadaPorcentaje)%" -ForegroundColor White
        Write-Host "  Cambio: $(if ($diffRAM -gt 0) { '+' })$diffRAM%" -ForegroundColor $colorRAM
        Write-Host ""
        
        # Disco
        $diffDisco = $despues.DiscoLibreGB - $antes.DiscoLibreGB
        $colorDisco = if ($diffDisco -ge 0) { "Green" } else { "Red" }
        Write-Host "Espacio Libre en Disco:" -ForegroundColor Yellow
        Write-Host "  Antes:  $($antes.DiscoLibreGB) GB" -ForegroundColor White
        Write-Host "  Después: $($despues.DiscoLibreGB) GB" -ForegroundColor White
        Write-Host "  Liberado: $(if ($diffDisco -gt 0) { '+' })$([math]::Round($diffDisco, 2)) GB" -ForegroundColor $colorDisco
        Write-Host ""
        
        # Servicios
        $diffServ = $despues.ServiciosEnEjecucion - $antes.ServiciosEnEjecucion
        $colorServ = if ($diffServ -le 0) { "Green" } else { "Yellow" }
        Write-Host "Servicios en Ejecución:" -ForegroundColor Yellow
        Write-Host "  Antes:  $($antes.ServiciosEnEjecucion)" -ForegroundColor White
        Write-Host "  Después: $($despues.ServiciosEnEjecucion)" -ForegroundColor White
        Write-Host "  Cambio: $(if ($diffServ -gt 0) { '+' })$diffServ" -ForegroundColor $colorServ
        Write-Host ""
        
        # Programas en inicio
        $diffInicio = $despues.ProgramasInicio - $antes.ProgramasInicio
        $colorInicio = if ($diffInicio -le 0) { "Green" } else { "Yellow" }
        Write-Host "Programas en Inicio:" -ForegroundColor Yellow
        Write-Host "  Antes:  $($antes.ProgramasInicio)" -ForegroundColor White
        Write-Host "  Después: $($despues.ProgramasInicio)" -ForegroundColor White
        Write-Host "  Cambio: $(if ($diffInicio -gt 0) { '+' })$diffInicio" -ForegroundColor $colorInicio
        Write-Host ""
        
        # Resumen
        $mejoras = 0
        if ($diffCPU -le 0) { $mejoras++ }
        if ($diffRAM -le 0) { $mejoras++ }
        if ($diffDisco -ge 0) { $mejoras++ }
        if ($diffServ -le 0) { $mejoras++ }
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "RESUMEN:" -ForegroundColor Yellow
        Write-Host "  Mejoras detectadas: $mejoras/4" -ForegroundColor $(if ($mejoras -ge 3) { "Green" } else { "Yellow" })
        
        if ($mejoras -ge 3) {
            Write-Host "  ✅ Optimización exitosa!" -ForegroundColor Green
        } elseif ($mejoras -ge 2) {
            Write-Host "  ⚠️  Optimización parcial" -ForegroundColor Yellow
        } else {
            Write-Host "  ℹ️  Sin mejoras significativas" -ForegroundColor Gray
        }
        
        Write-Host "========================================" -ForegroundColor Cyan
        
        Write-Log "Comparación completada: $mejoras/4 mejoras" -Level "SUCCESS"
    }
    '3' {
        if (-not (Test-Path $snapshotPath)) {
            Write-Host "❌ No hay snapshot guardado" -ForegroundColor Red
            break
        }
        
        $snapshot = Get-Content $snapshotPath | ConvertFrom-Json
        Write-Host ""
        Write-Host "📸 Snapshot guardado el $($snapshot.Fecha):" -ForegroundColor Cyan
        Write-Host "  • CPU: $($snapshot.CPU)%" -ForegroundColor White
        Write-Host "  • RAM usada: $($snapshot.RAMUsadaPorcentaje)%" -ForegroundColor White
        Write-Host "  • Disco libre: $($snapshot.DiscoLibreGB) GB" -ForegroundColor White
        Write-Host "  • Servicios: $($snapshot.ServiciosEnEjecucion)" -ForegroundColor White
        Write-Host "  • Programas inicio: $($snapshot.ProgramasInicio)" -ForegroundColor White
    }
    default {
        Write-Host "Opción inválida" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

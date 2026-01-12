# ============================================
# Analizar-Hardware.ps1
# Análisis detallado de hardware del sistema
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ANÁLISIS DE HARDWARE DETALLADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando análisis de hardware del sistema" -Level "INFO"

$reportPath = "$scriptPath\Reporte-Hardware-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$report = @()
$report += "=================================================="
$report += "REPORTE DE HARDWARE - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "=================================================="
$report += ""

# ============================================
# 1. CPU - PROCESADOR
# ============================================

Write-Host "[1/7] Analizando CPU..." -ForegroundColor Cyan

$report += "1. PROCESADOR (CPU)"
$report += "-" * 50

try {
    $cpu = Get-WmiObject Win32_Processor
    
    Write-Host "  • Modelo: $($cpu.Name)" -ForegroundColor White
    $report += "Modelo: $($cpu.Name)"
    
    Write-Host "  • Núcleos físicos: $($cpu.NumberOfCores)" -ForegroundColor White
    Write-Host "  • Núcleos lógicos: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White
    $report += "Núcleos físicos: $($cpu.NumberOfCores)"
    $report += "Núcleos lógicos: $($cpu.NumberOfLogicalProcessors)"
    
    Write-Host "  • Velocidad: $($cpu.MaxClockSpeed) MHz" -ForegroundColor White
    $report += "Velocidad máxima: $($cpu.MaxClockSpeed) MHz"
    
    # Uso actual de CPU
    $cpuLoad = (Get-WmiObject Win32_Processor).LoadPercentage
    Write-Host "  • Uso actual: $cpuLoad%" -ForegroundColor $(if ($cpuLoad -lt 50) { "Green" } elseif ($cpuLoad -lt 80) { "Yellow" } else { "Red" })
    $report += "Uso actual: $cpuLoad%"
    
    # Temperatura (requiere WMI específico o OpenHardwareMonitor)
    Write-Host "  • Temperatura: No disponible (requiere sensor específico)" -ForegroundColor Gray
    $report += "Temperatura: No disponible sin herramientas externas"
    
    Write-Log "CPU analizada: $($cpu.Name), $($cpu.NumberOfCores) cores" -Level "INFO"
} catch {
    Write-Host "  ❌ Error al analizar CPU" -ForegroundColor Red
    Write-Log "Error al analizar CPU: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 2. MEMORIA RAM
# ============================================

Write-Host "[2/7] Analizando Memoria RAM..." -ForegroundColor Cyan

$report += "2. MEMORIA RAM"
$report += "-" * 50

try {
    $os = Get-WmiObject Win32_OperatingSystem
    $cs = Get-WmiObject Win32_ComputerSystem
    
    $totalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = [math]::Round($totalRAM - ($freeRAM / 1024), 2)
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    Write-Host "  • Capacidad total: $totalRAM GB" -ForegroundColor White
    Write-Host "  • En uso: $usedRAM GB ($ramPercent%)" -ForegroundColor $(if ($ramPercent -lt 70) { "Green" } elseif ($ramPercent -lt 85) { "Yellow" } else { "Red" })
    Write-Host "  • Disponible: $([math]::Round($freeRAM / 1024, 2)) GB" -ForegroundColor White
    
    $report += "Capacidad total: $totalRAM GB"
    $report += "En uso: $usedRAM GB ($ramPercent%)"
    $report += "Disponible: $([math]::Round($freeRAM / 1024, 2)) GB"
    
    # Módulos de RAM
    $ramModules = Get-WmiObject Win32_PhysicalMemory
    Write-Host "  • Módulos instalados: $($ramModules.Count)" -ForegroundColor White
    $report += "Módulos instalados: $($ramModules.Count)"
    
    foreach ($module in $ramModules) {
        $capacity = [math]::Round($module.Capacity / 1GB, 0)
        $speed = $module.Speed
        Write-Host "    - $capacity GB @ $speed MHz" -ForegroundColor Gray
        $report += "  - $capacity GB @ $speed MHz"
    }
    
    Write-Log "RAM analizada: $totalRAM GB total, $ramPercent% en uso" -Level "INFO"
} catch {
    Write-Host "  ❌ Error al analizar RAM" -ForegroundColor Red
    Write-Log "Error al analizar RAM: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 3. DISCOS Y ALMACENAMIENTO
# ============================================

Write-Host "[3/7] Analizando Discos..." -ForegroundColor Cyan

$report += "3. ALMACENAMIENTO"
$report += "-" * 50

try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($disk in $disks) {
        $total = [math]::Round($disk.Size / 1GB, 2)
        $free = [math]::Round($disk.FreeSpace / 1GB, 2)
        $used = [math]::Round($total - $free, 2)
        $percent = [math]::Round(($used / $total) * 100, 1)
        
        Write-Host "  Disco $($disk.DeviceID)" -ForegroundColor White
        Write-Host "    • Capacidad: $total GB" -ForegroundColor White
        Write-Host "    • Usado: $used GB ($percent%)" -ForegroundColor $(if ($percent -lt 80) { "Green" } elseif ($percent -lt 90) { "Yellow" } else { "Red" })
        Write-Host "    • Libre: $free GB" -ForegroundColor White
        
        $report += "Disco $($disk.DeviceID)"
        $report += "  Capacidad: $total GB"
        $report += "  Usado: $used GB ($percent%)"
        $report += "  Libre: $free GB"
        
        # Tipo de disco (SSD/HDD) - Detección básica
        $physicalDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -First 1
        if ($physicalDisk) {
            $mediaType = $physicalDisk.MediaType
            Write-Host "    • Tipo: $mediaType" -ForegroundColor White
            $report += "  Tipo: $mediaType"
        }
        
        Write-Host ""
    }
    
    # SMART Status (solo en Windows 8+)
    try {
        $smartDisks = Get-PhysicalDisk
        Write-Host "  Estado SMART:" -ForegroundColor Cyan
        foreach ($smart in $smartDisks) {
            $health = $smart.HealthStatus
            $colorHealth = if ($health -eq "Healthy") { "Green" } else { "Red" }
            Write-Host "    • Disco $($smart.FriendlyName): $health" -ForegroundColor $colorHealth
            $report += "  SMART - $($smart.FriendlyName): $health"
        }
    } catch {
        Write-Host "  ℹ️  Estado SMART no disponible" -ForegroundColor Gray
    }
    
    Write-Log "Discos analizados: $($disks.Count) volúmenes" -Level "INFO"
} catch {
    Write-Host "  ❌ Error al analizar discos" -ForegroundColor Red
    Write-Log "Error al analizar discos: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 4. TARJETA GRÁFICA (GPU)
# ============================================

Write-Host "[4/7] Analizando Tarjeta Gráfica..." -ForegroundColor Cyan

$report += "4. TARJETA GRÁFICA (GPU)"
$report += "-" * 50

try {
    $gpus = Get-WmiObject Win32_VideoController
    
    foreach ($gpu in $gpus) {
        Write-Host "  • Modelo: $($gpu.Name)" -ForegroundColor White
        $report += "Modelo: $($gpu.Name)"
        
        $vram = [math]::Round($gpu.AdapterRAM / 1GB, 2)
        if ($vram -gt 0) {
            Write-Host "  • VRAM: $vram GB" -ForegroundColor White
            $report += "VRAM: $vram GB"
        }
        
        Write-Host "  • Resolución: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)" -ForegroundColor White
        $report += "Resolución: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)"
        
        Write-Host "  • Driver: $($gpu.DriverVersion)" -ForegroundColor White
        $report += "Driver: $($gpu.DriverVersion)"
        
        Write-Host "  • Temperatura: No disponible (requiere GPU-Z o similar)" -ForegroundColor Gray
        $report += "Temperatura: Requiere software específico"
    }
    
    Write-Log "GPU analizada: $($gpus[0].Name)" -Level "INFO"
} catch {
    Write-Host "  ❌ Error al analizar GPU" -ForegroundColor Red
    Write-Log "Error al analizar GPU: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 5. PLACA BASE (MOTHERBOARD)
# ============================================

Write-Host "[5/7] Analizando Placa Base..." -ForegroundColor Cyan

$report += "5. PLACA BASE (MOTHERBOARD)"
$report += "-" * 50

try {
    $motherboard = Get-WmiObject Win32_BaseBoard
    $bios = Get-WmiObject Win32_BIOS
    
    Write-Host "  • Fabricante: $($motherboard.Manufacturer)" -ForegroundColor White
    Write-Host "  • Modelo: $($motherboard.Product)" -ForegroundColor White
    Write-Host "  • BIOS: $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)" -ForegroundColor White
    Write-Host "  • Fecha BIOS: $($bios.ReleaseDate.Substring(0,8))" -ForegroundColor White
    
    $report += "Fabricante: $($motherboard.Manufacturer)"
    $report += "Modelo: $($motherboard.Product)"
    $report += "BIOS: $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"
    $report += "Fecha BIOS: $($bios.ReleaseDate.Substring(0,8))"
    
    Write-Log "Placa base: $($motherboard.Manufacturer) $($motherboard.Product)" -Level "INFO"
} catch {
    Write-Host "  ⚠️  Información limitada de placa base" -ForegroundColor Yellow
}

$report += ""
Write-Host ""

# ============================================
# 6. BENCHMARK RÁPIDO
# ============================================

Write-Host "[6/7] Ejecutando Benchmark Rápido..." -ForegroundColor Cyan
Write-Host "  (Esto puede tardar 10-15 segundos)" -ForegroundColor Gray
Write-Host ""

$report += "6. BENCHMARK RÁPIDO"
$report += "-" * 50

try {
    # Test de CPU (cálculo de números primos)
    Write-Host "  🔄 Test CPU..." -ForegroundColor Yellow
    $cpuStart = Get-Date
    $primes = 0
    for ($i = 2; $i -lt 10000; $i++) {
        $isPrime = $true
        for ($j = 2; $j -lt $i; $j++) {
            if ($i % $j -eq 0) {
                $isPrime = $false
                break
            }
        }
        if ($isPrime) { $primes++ }
    }
    $cpuTime = ((Get-Date) - $cpuStart).TotalSeconds
    Write-Host "  ✅ CPU Score: $([math]::Round(1000 / $cpuTime, 0)) pts (menor tiempo = mejor)" -ForegroundColor Green
    $report += "CPU Benchmark: $([math]::Round(1000 / $cpuTime, 0)) puntos"
    
    # Test de RAM (escritura/lectura)
    Write-Host "  🔄 Test RAM..." -ForegroundColor Yellow
    $ramStart = Get-Date
    $array = 1..1000000
    $sum = ($array | Measure-Object -Sum).Sum
    $ramTime = ((Get-Date) - $ramStart).TotalSeconds
    Write-Host "  ✅ RAM Score: $([math]::Round(1000 / $ramTime, 0)) pts" -ForegroundColor Green
    $report += "RAM Benchmark: $([math]::Round(1000 / $ramTime, 0)) puntos"
    
    # Test de Disco (escritura)
    Write-Host "  🔄 Test Disco..." -ForegroundColor Yellow
    $diskStart = Get-Date
    $testFile = "$env:TEMP\benchmark_test.tmp"
    1..10000 | Out-File $testFile
    $diskTime = ((Get-Date) - $diskStart).TotalSeconds
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    Write-Host "  ✅ Disco Score: $([math]::Round(1000 / $diskTime, 0)) pts" -ForegroundColor Green
    $report += "Disco Benchmark: $([math]::Round(1000 / $diskTime, 0)) puntos"
    
    # Puntuación general
    $overallScore = [math]::Round((1000/$cpuTime + 1000/$ramTime + 1000/$diskTime) / 3, 0)
    Write-Host ""
    Write-Host "  📊 PUNTUACIÓN GENERAL: $overallScore pts" -ForegroundColor Cyan
    $report += ""
    $report += "PUNTUACIÓN GENERAL: $overallScore puntos"
    
    Write-Log "Benchmark completado: Score general $overallScore" -Level "SUCCESS"
} catch {
    Write-Host "  ⚠️  Error en benchmark" -ForegroundColor Yellow
}

$report += ""
Write-Host ""

# ============================================
# 7. RESUMEN Y RECOMENDACIONES
# ============================================

Write-Host "[7/7] Generando Recomendaciones..." -ForegroundColor Cyan

$report += "7. RECOMENDACIONES"
$report += "-" * 50

$recomendaciones = @()

# Recomendaciones basadas en RAM
if ($ramPercent -gt 85) {
    $recomendaciones += "⚠️  Uso de RAM alto ($ramPercent%). Considera cerrar programas o ampliar memoria."
    Write-Host "  ⚠️  RAM: Uso alto ($ramPercent%)" -ForegroundColor Yellow
}

# Recomendaciones basadas en disco
foreach ($disk in $disks) {
    $percent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    if ($percent -gt 90) {
        $recomendaciones += "⚠️  Disco $($disk.DeviceID) casi lleno ($percent%). Libera espacio."
        Write-Host "  ⚠️  Disco $($disk.DeviceID): Casi lleno ($percent%)" -ForegroundColor Yellow
    }
}

# Recomendaciones de hardware
if ($totalRAM -lt 8) {
    $recomendaciones += "💡 Considera ampliar RAM a 8GB o más para mejor rendimiento."
    Write-Host "  💡 RAM: Considera ampliar a 8GB+" -ForegroundColor Cyan
}

if ($recomendaciones.Count -eq 0) {
    $recomendaciones += "✅ Hardware en buen estado. No hay recomendaciones críticas."
    Write-Host "  ✅ Hardware en buen estado" -ForegroundColor Green
}

foreach ($rec in $recomendaciones) {
    $report += $rec
}

Write-Host ""

# ============================================
# GUARDAR REPORTE
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ANÁLISIS COMPLETADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📄 Reporte guardado en:" -ForegroundColor Cyan
Write-Host "   $reportPath" -ForegroundColor Gray

$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Log "Análisis de hardware completado. Reporte guardado en $reportPath" -Level "SUCCESS"

Write-Host ""
Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

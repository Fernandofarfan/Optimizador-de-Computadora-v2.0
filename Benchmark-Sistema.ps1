#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Suite Profesional de Benchmarks del Sistema
.DESCRIPTION
    Herramienta completa para medir el rendimiento del sistema:
    - Benchmark de CPU (cálculo de números primos)
    - Benchmark de RAM (velocidad lectura/escritura)
    - Benchmark de Disco (secuencial y aleatorio)
    - Benchmark de GPU (si está disponible)
    - Comparación con histórico de resultados
    - Puntuación global del sistema
    - Exportación de resultados
.NOTES
    Versión: 2.8.0
    Requiere: Windows 10/11, PowerShell 5.1+, Privilegios de administrador
#>

# Importar Logger si existe
if (Test-Path "$PSScriptRoot\Logger.ps1") {
    . "$PSScriptRoot\Logger.ps1"
}

$Global:BenchmarkHistoryPath = "$env:USERPROFILE\OptimizadorPC-Benchmarks.json"

function Write-ColoredText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Clear-Host
    Write-ColoredText "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColoredText "║           SUITE DE BENCHMARKS DEL SISTEMA v2.8.0           ║" "Cyan"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Test-CPUPerformance {
    <#
    .SYNOPSIS
        Prueba de rendimiento de CPU mediante cálculo de números primos
    #>
    param(
        [int]$MaxNumber = 100000
    )
    
    Write-ColoredText "`n🔧 BENCHMARK DE CPU" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    # Obtener información del CPU
    $cpu = Get-WmiObject Win32_Processor
    Write-Host "CPU: $($cpu.Name)"
    Write-Host "Núcleos: $($cpu.NumberOfCores)"
    Write-Host "Hilos: $($cpu.NumberOfLogicalProcessors)"
    Write-Host "Frecuencia: $($cpu.MaxClockSpeed) MHz"
    Write-Host ""
    
    Write-ColoredText "Calculando números primos hasta $MaxNumber..." "Yellow"
    Write-Host ""
    
    # Función para calcular primos (prueba de CPU)
    $primesScript = {
        param($max)
        $primes = @()
        $isPrime = $true
        
        for ($num = 2; $num -le $max; $num++) {
            $isPrime = $true
            $sqrt = [Math]::Sqrt($num)
            
            for ($i = 2; $i -le $sqrt; $i++) {
                if ($num % $i -eq 0) {
                    $isPrime = $false
                    break
                }
            }
            
            if ($isPrime) {
                $primes += $num
            }
        }
        
        return $primes.Count
    }
    
    # Prueba Single-Core
    Write-ColoredText "⏱️ Prueba Single-Core..." "Yellow"
    $singleStart = Get-Date
    $primeCount = & $primesScript $MaxNumber
    $singleEnd = Get-Date
    $singleTime = ($singleEnd - $singleStart).TotalSeconds
    
    Write-ColoredText "✅ Completado en $([math]::Round($singleTime, 2)) segundos" "Green"
    Write-Host "   Números primos encontrados: $primeCount"
    Write-Host ""
    
    # Prueba Multi-Core (dividir trabajo en threads)
    Write-ColoredText "⏱️ Prueba Multi-Core ($($cpu.NumberOfLogicalProcessors) hilos)..." "Yellow"
    
    $multiStart = Get-Date
    
    $jobs = @()
    $rangeSize = [math]::Ceiling($MaxNumber / $cpu.NumberOfLogicalProcessors)
    
    for ($i = 0; $i -lt $cpu.NumberOfLogicalProcessors; $i++) {
        $start = ($i * $rangeSize) + 2
        $end = [math]::Min(($i + 1) * $rangeSize, $MaxNumber)
        
        if ($start -le $end) {
            $jobs += Start-Job -ScriptBlock $primesScript -ArgumentList $end
        }
    }
    
    $jobs | Wait-Job | Out-Null
    $jobs | Remove-Job
    
    $multiEnd = Get-Date
    $multiTime = ($multiEnd - $multiStart).TotalSeconds
    
    Write-ColoredText "✅ Completado en $([math]::Round($multiTime, 2)) segundos" "Green"
    Write-Host ""
    
    # Calcular puntuación
    $baseTime = 10.0  # Tiempo de referencia en segundos
    $singleScore = [math]::Round(($baseTime / $singleTime) * 1000, 0)
    $multiScore = [math]::Round(($baseTime / $multiTime) * 1000, 0)
    $speedup = [math]::Round($singleTime / $multiTime, 2)
    
    Write-ColoredText "📊 RESULTADOS CPU:" "Cyan"
    Write-Host "   Puntuación Single-Core: $singleScore puntos"
    Write-Host "   Puntuación Multi-Core: $multiScore puntos"
    Write-Host "   Aceleración Multi-Core: ${speedup}x"
    Write-Host ""
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Benchmark CPU: Single=$singleScore, Multi=$multiScore, Speedup=${speedup}x" "Info"
    }
    
    return @{
        SingleCoreScore = $singleScore
        MultiCoreScore = $multiScore
        SingleCoreTime = $singleTime
        MultiCoreTime = $multiTime
        Speedup = $speedup
        CPUName = $cpu.Name
        Cores = $cpu.NumberOfCores
        Threads = $cpu.NumberOfLogicalProcessors
    }
}

function Test-RAMPerformance {
    <#
    .SYNOPSIS
        Prueba de rendimiento de RAM (velocidad lectura/escritura)
    #>
    param(
        [int]$ArraySizeMB = 512
    )
    
    Write-ColoredText "`n💾 BENCHMARK DE RAM" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    # Obtener información de RAM
    $ram = Get-WmiObject Win32_PhysicalMemory
    $totalRAM = [math]::Round(($ram | Measure-Object Capacity -Sum).Sum / 1GB, 2)
    
    Write-Host "RAM Total: $totalRAM GB"
    Write-Host "Módulos: $($ram.Count)"
    Write-Host "Velocidad: $($ram[0].Speed) MHz"
    Write-Host ""
    
    # Prueba de escritura
    Write-ColoredText "⏱️ Prueba de Escritura (${ArraySizeMB} MB)..." "Yellow"
    
    $arraySize = $ArraySizeMB * 1024 * 1024 / 8  # Convertir a número de elementos (8 bytes por double)
    
    $writeStart = Get-Date
    $array = New-Object double[] $arraySize
    for ($i = 0; $i -lt $array.Length; $i++) {
        $array[$i] = $i * 3.14159
    }
    $writeEnd = Get-Date
    $writeTime = ($writeEnd - $writeStart).TotalSeconds
    $writeMBps = [math]::Round($ArraySizeMB / $writeTime, 2)
    
    Write-ColoredText "✅ Completado en $([math]::Round($writeTime, 2)) segundos" "Green"
    Write-Host "   Velocidad de escritura: $writeMBps MB/s"
    Write-Host ""
    
    # Prueba de lectura
    Write-ColoredText "⏱️ Prueba de Lectura (${ArraySizeMB} MB)..." "Yellow"
    
    $readStart = Get-Date
    $sum = 0.0
    for ($i = 0; $i -lt $array.Length; $i++) {
        $sum += $array[$i]
    }
    $readEnd = Get-Date
    $readTime = ($readEnd - $readStart).TotalSeconds
    $readMBps = [math]::Round($ArraySizeMB / $readTime, 2)
    
    Write-ColoredText "✅ Completado en $([math]::Round($readTime, 2)) segundos" "Green"
    Write-Host "   Velocidad de lectura: $readMBps MB/s"
    Write-Host ""
    
    # Prueba de copia
    Write-ColoredText "⏱️ Prueba de Copia (${ArraySizeMB} MB)..." "Yellow"
    
    $copyStart = Get-Date
    $array2 = New-Object double[] $arraySize
    [Array]::Copy($array, $array2, $array.Length)
    $copyEnd = Get-Date
    $copyTime = ($copyEnd - $copyStart).TotalSeconds
    $copyMBps = [math]::Round($ArraySizeMB / $copyTime, 2)
    
    Write-ColoredText "✅ Completado en $([math]::Round($copyTime, 2)) segundos" "Green"
    Write-Host "   Velocidad de copia: $copyMBps MB/s"
    Write-Host ""
    
    # Calcular puntuación
    $baseSpeed = 5000  # MB/s de referencia
    $avgSpeed = ($writeMBps + $readMBps + $copyMBps) / 3
    $score = [math]::Round(($avgSpeed / $baseSpeed) * 1000, 0)
    
    Write-ColoredText "📊 RESULTADOS RAM:" "Cyan"
    Write-Host "   Escritura: $writeMBps MB/s"
    Write-Host "   Lectura: $readMBps MB/s"
    Write-Host "   Copia: $copyMBps MB/s"
    Write-Host "   Promedio: $([math]::Round($avgSpeed, 2)) MB/s"
    Write-Host "   Puntuación: $score puntos"
    Write-Host ""
    
    # Limpiar arrays
    $array = $null
    $array2 = $null
    [System.GC]::Collect()
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Benchmark RAM: Write=$writeMBps MB/s, Read=$readMBps MB/s, Copy=$copyMBps MB/s, Score=$score" "Info"
    }
    
    return @{
        WriteSpeed = $writeMBps
        ReadSpeed = $readMBps
        CopySpeed = $copyMBps
        AverageSpeed = [math]::Round($avgSpeed, 2)
        Score = $score
        TotalRAM = $totalRAM
    }
}

function Test-DiskPerformance {
    <#
    .SYNOPSIS
        Prueba de rendimiento de disco (lectura/escritura secuencial y aleatoria)
    #>
    param(
        [string]$DriveLetter = "C",
        [int]$FileSizeMB = 100
    )
    
    Write-ColoredText "`n💿 BENCHMARK DE DISCO" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    # Obtener información del disco
    $disk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 }
    $volume = Get-Volume -DriveLetter $DriveLetter
    
    Write-Host "Disco: $($disk.FriendlyName)"
    Write-Host "Tipo: $($disk.MediaType)"
    Write-Host "Tamaño: $([math]::Round($volume.Size / 1GB, 2)) GB"
    Write-Host "Libre: $([math]::Round($volume.SizeRemaining / 1GB, 2)) GB"
    Write-Host ""
    
    $testFilePath = "${DriveLetter}:\OptimizadorPC-BenchmarkTest.tmp"
    
    # Prueba de escritura secuencial
    Write-ColoredText "⏱️ Escritura Secuencial (${FileSizeMB} MB)..." "Yellow"
    
    $buffer = New-Object byte[] (1024 * 1024)  # 1 MB buffer
    $random = New-Object Random
    $random.NextBytes($buffer)
    
    $writeStart = Get-Date
    try {
        $fileStream = [System.IO.File]::Create($testFilePath)
        for ($i = 0; $i -lt $FileSizeMB; $i++) {
            $fileStream.Write($buffer, 0, $buffer.Length)
        }
        $fileStream.Flush()
        $fileStream.Close()
    }
    catch {
        Write-ColoredText "❌ Error en escritura: $($_.Exception.Message)" "Red"
        return $null
    }
    $writeEnd = Get-Date
    $writeTime = ($writeEnd - $writeStart).TotalSeconds
    $writeMBps = [math]::Round($FileSizeMB / $writeTime, 2)
    
    Write-ColoredText "✅ Completado: $writeMBps MB/s" "Green"
    Write-Host ""
    
    # Prueba de lectura secuencial
    Write-ColoredText "⏱️ Lectura Secuencial (${FileSizeMB} MB)..." "Yellow"
    
    $readStart = Get-Date
    try {
        $fileStream = [System.IO.File]::OpenRead($testFilePath)
        $readBuffer = New-Object byte[] (1024 * 1024)
        while ($fileStream.Read($readBuffer, 0, $readBuffer.Length) -gt 0) {
            # Leer datos
        }
        $fileStream.Close()
    }
    catch {
        Write-ColoredText "❌ Error en lectura: $($_.Exception.Message)" "Red"
        return $null
    }
    $readEnd = Get-Date
    $readTime = ($readEnd - $readStart).TotalSeconds
    $readMBps = [math]::Round($FileSizeMB / $readTime, 2)
    
    Write-ColoredText "✅ Completado: $readMBps MB/s" "Green"
    Write-Host ""
    
    # Prueba de lectura aleatoria (4K blocks)
    Write-ColoredText "⏱️ Lectura Aleatoria (4K blocks)..." "Yellow"
    
    $blockSize = 4096  # 4KB
    $numReads = 1000
    
    $randomStart = Get-Date
    try {
        $fileStream = [System.IO.File]::OpenRead($testFilePath)
        $randomBuffer = New-Object byte[] $blockSize
        $fileSize = $fileStream.Length
        
        for ($i = 0; $i -lt $numReads; $i++) {
            $randomPos = $random.Next(0, $fileSize - $blockSize)
            $fileStream.Seek($randomPos, [System.IO.SeekOrigin]::Begin) | Out-Null
            $fileStream.Read($randomBuffer, 0, $blockSize) | Out-Null
        }
        
        $fileStream.Close()
    }
    catch {
        Write-ColoredText "❌ Error en lectura aleatoria: $($_.Exception.Message)" "Red"
        return $null
    }
    $randomEnd = Get-Date
    $randomTime = ($randomEnd - $randomStart).TotalSeconds
    $iops = [math]::Round($numReads / $randomTime, 0)
    
    Write-ColoredText "✅ Completado: $iops IOPS" "Green"
    Write-Host ""
    
    # Limpiar archivo de prueba
    try {
        Remove-Item $testFilePath -Force -ErrorAction SilentlyContinue
    }
    catch { }
    
    # Calcular puntuación
    $baseWriteSpeed = if ($disk.MediaType -eq "SSD") { 500 } else { 100 }  # MB/s de referencia
    $baseReadSpeed = if ($disk.MediaType -eq "SSD") { 500 } else { 100 }
    $baseIOPS = if ($disk.MediaType -eq "SSD") { 50000 } else { 100 }
    
    $writeScore = [math]::Round(($writeMBps / $baseWriteSpeed) * 1000, 0)
    $readScore = [math]::Round(($readMBps / $baseReadSpeed) * 1000, 0)
    $iopsScore = [math]::Round(($iops / $baseIOPS) * 1000, 0)
    $avgScore = [math]::Round(($writeScore + $readScore + $iopsScore) / 3, 0)
    
    Write-ColoredText "📊 RESULTADOS DISCO:" "Cyan"
    Write-Host "   Escritura Secuencial: $writeMBps MB/s ($writeScore puntos)"
    Write-Host "   Lectura Secuencial: $readMBps MB/s ($readScore puntos)"
    Write-Host "   Lectura Aleatoria: $iops IOPS ($iopsScore puntos)"
    Write-Host "   Puntuación Promedio: $avgScore puntos"
    Write-Host ""
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Benchmark Disco: Write=$writeMBps MB/s, Read=$readMBps MB/s, IOPS=$iops, Score=$avgScore" "Info"
    }
    
    return @{
        WriteSpeed = $writeMBps
        ReadSpeed = $readMBps
        IOPS = $iops
        WriteScore = $writeScore
        ReadScore = $readScore
        IOPSScore = $iopsScore
        AverageScore = $avgScore
        MediaType = $disk.MediaType
    }
}

function Save-BenchmarkResults {
    <#
    .SYNOPSIS
        Guarda los resultados del benchmark en el historial
    #>
    param(
        [hashtable]$CPUResult,
        [hashtable]$RAMResult,
        [hashtable]$DiskResult
    )
    
    # Calcular puntuación global
    $globalScore = [math]::Round((
        $CPUResult.MultiCoreScore * 0.4 +
        $RAMResult.Score * 0.3 +
        $DiskResult.AverageScore * 0.3
    ), 0)
    
    $result = @{
        Fecha = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        CPU = $CPUResult
        RAM = $RAMResult
        Disco = $DiskResult
        PuntuacionGlobal = $globalScore
        Sistema = @{
            OS = (Get-WmiObject Win32_OperatingSystem).Caption
            Version = (Get-WmiObject Win32_OperatingSystem).Version
            Arquitectura = $env:PROCESSOR_ARCHITECTURE
        }
    }
    
    # Cargar historial existente
    $history = @()
    if (Test-Path $Global:BenchmarkHistoryPath) {
        try {
            $historyTemp = Get-Content $Global:BenchmarkHistoryPath -Raw | ConvertFrom-Json
            $history = @($historyTemp)
        }
        catch {
            $history = @()
        }
    }
    
    # Agregar nuevo resultado
    $history += $result
    
    # Guardar (mantener últimos 50 resultados)
    if ($history.Count -gt 50) {
        $history = $history | Select-Object -Last 50
    }
    
    try {
        $history | ConvertTo-Json -Depth 10 | Out-File $Global:BenchmarkHistoryPath -Encoding UTF8
        Write-ColoredText "✅ Resultados guardados en historial" "Green"
    }
    catch {
        Write-ColoredText "⚠ No se pudo guardar el historial: $($_.Exception.Message)" "Yellow"
    }
    
    return $globalScore
}

function Show-BenchmarkHistory {
    <#
    .SYNOPSIS
        Muestra el historial de benchmarks con comparaciones
    #>
    Write-ColoredText "`n📊 HISTORIAL DE BENCHMARKS" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    if (-not (Test-Path $Global:BenchmarkHistoryPath)) {
        Write-ColoredText "⚠ No hay historial de benchmarks disponible" "Yellow"
        return
    }
    
    try {
        $historyTemp = Get-Content $Global:BenchmarkHistoryPath -Raw | ConvertFrom-Json
        $history = @($historyTemp)
        
        if ($history.Count -eq 0) {
            Write-ColoredText "⚠ No hay resultados en el historial" "Yellow"
            return
        }
        
        Write-Host "Mostrando últimos $([math]::Min(10, $history.Count)) resultados:"
        Write-Host ""
        
        $recent = $history | Select-Object -Last 10
        
        foreach ($result in $recent) {
            Write-ColoredText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Gray"
            Write-Host "Fecha: $($result.Fecha)"
            Write-Host "Puntuación Global: $($result.PuntuacionGlobal) puntos"
            Write-Host ""
            Write-Host "CPU:"
            Write-Host "  • Single-Core: $($result.CPU.SingleCoreScore) puntos"
            Write-Host "  • Multi-Core: $($result.CPU.MultiCoreScore) puntos"
            Write-Host "  • Aceleración: $($result.CPU.Speedup)x"
            Write-Host ""
            Write-Host "RAM:"
            Write-Host "  • Puntuación: $($result.RAM.Score) puntos"
            Write-Host "  • Velocidad Promedio: $($result.RAM.AverageSpeed) MB/s"
            Write-Host ""
            Write-Host "Disco:"
            Write-Host "  • Puntuación: $($result.Disco.AverageScore) puntos"
            Write-Host "  • Escritura: $($result.Disco.WriteSpeed) MB/s"
            Write-Host "  • Lectura: $($result.Disco.ReadSpeed) MB/s"
            Write-Host "  • IOPS: $($result.Disco.IOPS)"
            Write-Host ""
        }
        
        # Mostrar tendencias
        if ($history.Count -ge 2) {
            $latest = $history[-1]
            $previous = $history[-2]
            
            $improvement = $latest.PuntuacionGlobal - $previous.PuntuacionGlobal
            $improvementPercent = [math]::Round(($improvement / $previous.PuntuacionGlobal) * 100, 2)
            
            Write-ColoredText "📈 COMPARACIÓN CON RESULTADO ANTERIOR:" "Cyan"
            
            if ($improvement -gt 0) {
                Write-ColoredText "   ⬆ Mejora de $improvement puntos (+$improvementPercent%)" "Green"
            }
            elseif ($improvement -lt 0) {
                Write-ColoredText "   ⬇ Disminución de $([math]::Abs($improvement)) puntos ($improvementPercent%)" "Red"
            }
            else {
                Write-ColoredText "   ➡ Sin cambios" "Yellow"
            }
            
            Write-Host ""
        }
        
        Write-ColoredText "Total de benchmarks registrados: $($history.Count)" "Green"
    }
    catch {
        Write-ColoredText "❌ Error al leer historial: $($_.Exception.Message)" "Red"
    }
}

function Start-FullBenchmark {
    <#
    .SYNOPSIS
        Ejecuta suite completa de benchmarks
    #>
    Write-ColoredText "`n🚀 INICIANDO SUITE COMPLETA DE BENCHMARKS" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-ColoredText "⚠ IMPORTANTE:" "Yellow"
    Write-ColoredText "   • El proceso puede tardar 5-10 minutos" "White"
    Write-ColoredText "   • Cierra aplicaciones que consuman recursos" "White"
    Write-ColoredText "   • Conecta el portátil a la corriente eléctrica" "White"
    Write-Host ""
    
    $confirm = Read-Host "¿Continuar con el benchmark completo? (S/N)"
    
    if ($confirm -ne "S") {
        Write-ColoredText "❌ Benchmark cancelado" "Yellow"
        return
    }
    
    $totalStart = Get-Date
    
    # Benchmark CPU
    $cpuResult = Test-CPUPerformance -MaxNumber 100000
    
    # Benchmark RAM
    $ramResult = Test-RAMPerformance -ArraySizeMB 512
    
    # Benchmark Disco
    $diskResult = Test-DiskPerformance -DriveLetter "C" -FileSizeMB 100
    
    $totalEnd = Get-Date
    $totalTime = ($totalEnd - $totalStart).TotalSeconds
    
    # Guardar resultados
    $globalScore = Save-BenchmarkResults -CPUResult $cpuResult -RAMResult $ramResult -DiskResult $diskResult
    
    # Resumen final
    Write-ColoredText "`n╔══════════════════════════════════════════════════════════════╗" "Green"
    Write-ColoredText "║              RESUMEN DE RESULTADOS FINALES                   ║" "Green"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════╝" "Green"
    Write-Host ""
    
    Write-ColoredText "⏱️ Tiempo total: $([math]::Round($totalTime, 2)) segundos" "White"
    Write-Host ""
    
    Write-ColoredText "🔧 CPU: $($cpuResult.MultiCoreScore) puntos" "Cyan"
    Write-ColoredText "💾 RAM: $($ramResult.Score) puntos" "Cyan"
    Write-ColoredText "💿 Disco: $($diskResult.AverageScore) puntos" "Cyan"
    Write-Host ""
    
    Write-ColoredText "🏆 PUNTUACIÓN GLOBAL: $globalScore puntos" "Green"
    Write-Host ""
    
    # Clasificación del sistema
    $classification = if ($globalScore -ge 2000) { "⭐⭐⭐ Excelente" }
                      elseif ($globalScore -ge 1500) { "⭐⭐ Muy Bueno" }
                      elseif ($globalScore -ge 1000) { "⭐ Bueno" }
                      else { "⚠ Necesita actualización" }
    
    Write-ColoredText "Clasificación: $classification" "Yellow"
    Write-Host ""
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Benchmark completo: Global=$globalScore, CPU=$($cpuResult.MultiCoreScore), RAM=$($ramResult.Score), Disco=$($diskResult.AverageScore)" "Info"
    }
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

do {
    Show-Header
    
    Write-Host "  🎯 BENCHMARKS INDIVIDUALES"
    Write-Host "  ─────────────────────"
    Write-Host "  1. 🔧 Benchmark de CPU"
    Write-Host "  2. 💾 Benchmark de RAM"
    Write-Host "  3. 💿 Benchmark de Disco"
    Write-Host ""
    Write-Host "  🚀 COMPLETO"
    Write-Host "  ─────────────────────"
    Write-Host "  4. 🏆 Suite completa de benchmarks"
    Write-Host ""
    Write-Host "  📊 HISTORIAL"
    Write-Host "  ─────────────────────"
    Write-Host "  5. 📈 Ver historial y comparaciones"
    Write-Host ""
    Write-Host "  0. ↩️  Volver al menú principal"
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción"
    
    switch ($opcion) {
        "1" {
            Show-Header
            Test-CPUPerformance -MaxNumber 100000
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "2" {
            Show-Header
            Test-RAMPerformance -ArraySizeMB 512
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "3" {
            Show-Header
            $drive = Read-Host "Letra de unidad a probar (por defecto C)"
            if ([string]::IsNullOrWhiteSpace($drive)) { $drive = "C" }
            
            Test-DiskPerformance -DriveLetter $drive -FileSizeMB 100
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "4" {
            Show-Header
            Start-FullBenchmark
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "5" {
            Show-Header
            Show-BenchmarkHistory
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "0" {
            Write-ColoredText "`n✅ Volviendo al menú principal..." "Green"
            Start-Sleep -Seconds 1
        }
        default {
            Write-ColoredText "`n❌ Opción inválida" "Red"
            Start-Sleep -Seconds 2
        }
    }
} while ($opcion -ne "0")

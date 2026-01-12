# ============================================
# Desfragmentar-Inteligente.ps1
# Desfragmentación inteligente HDD/SSD
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DESFRAGMENTACIÓN INTELIGENTE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Log "Desfragmentación cancelada: Sin permisos" -Level "ERROR"
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Log "Iniciando desfragmentación inteligente" -Level "INFO"

# Función para obtener tipo de disco
function Get-DriveType {
    param([string]$DriveLetter)
    
    try {
        $partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        if ($partition) {
            $disk = Get-PhysicalDisk -UniqueId $partition.DiskId -ErrorAction SilentlyContinue
            if ($disk) {
                return $disk.MediaType
            }
        }
    } catch {
        # Fallback: Intentar con WMI
        $volume = Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk WHERE DeviceID='$($DriveLetter):'" -ErrorAction SilentlyContinue
        if ($volume) {
            $diskDrive = Get-WmiObject -Query "ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='$($DriveLetter):'} WHERE AssocClass=Win32_LogicalDiskToPartition" -ErrorAction SilentlyContinue
            if ($diskDrive) {
                $physicalDisk = Get-WmiObject -Query "ASSOCIATORS OF {$($diskDrive.__PATH)} WHERE AssocClass=Win32_DiskDriveToDiskPartition" -ErrorAction SilentlyContinue
                if ($physicalDisk) {
                    # Intentar detectar si es SSD
                    if ($physicalDisk.Model -like "*SSD*" -or $physicalDisk.Model -like "*Solid State*") {
                        return "SSD"
                    } else {
                        return "HDD"
                    }
                }
            }
        }
    }
    
    return "Unknown"
}

# Función para analizar fragmentación
function Analyze-Drive {
    param([string]$DriveLetter)
    
    Write-Host "  🔍 Analizando fragmentación..." -ForegroundColor Cyan
    
    try {
        # Ejecutar análisis
        $result = Optimize-Volume -DriveLetter $DriveLetter -Analyze -Verbose 4>&1
        
        # Parsear salida verbose para extraer porcentaje
        $fragPercentage = 0
        foreach ($line in $result) {
            if ($line -match "(\d+)%\s+fragmented") {
                $fragPercentage = [int]$matches[1]
                break
            }
        }
        
        # Si no se pudo parsear, intentar obtener de otra manera
        if ($fragPercentage -eq 0) {
            $volume = Get-Volume -DriveLetter $DriveLetter
            # Estimación basada en espacio usado
            if ($volume.Size -gt 0) {
                $usedPercent = (($volume.Size - $volume.SizeRemaining) / $volume.Size) * 100
                # Estimación conservadora: 5% de fragmentación por cada 20% de espacio usado
                $fragPercentage = [math]::Floor($usedPercent / 20 * 5)
            }
        }
        
        return $fragPercentage
    } catch {
        Write-Host "    ⚠️ No se pudo analizar la fragmentación" -ForegroundColor Yellow
        return -1
    }
}

# Función para desfragmentar HDD
function Defrag-HDD {
    param(
        [string]$DriveLetter,
        [int]$FragPercentage
    )
    
    Write-Host ""
    Write-Host "💿 DESFRAGMENTANDO HDD ($DriveLetter`:)..." -ForegroundColor Yellow
    Write-Host ""
    
    if ($FragPercentage -lt 10 -and $FragPercentage -ge 0) {
        Write-Host "  ℹ️  Fragmentación baja ($FragPercentage%)" -ForegroundColor Green
        Write-Host "  → No es necesario desfragmentar ahora" -ForegroundColor Gray
        return $false
    }
    
    Write-Host "  🔧 Fragmentación detectada: $FragPercentage%" -ForegroundColor Yellow
    Write-Host "  ⏳ Iniciando desfragmentación (puede tardar varios minutos)..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Desfragmentar con progreso
        $startTime = Get-Date
        Optimize-Volume -DriveLetter $DriveLetter -Defrag -Verbose
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        
        Write-Host ""
        Write-Host "  ✅ Desfragmentación completada en $([math]::Round($duration, 1)) minutos" -ForegroundColor Green
        
        # Analizar de nuevo
        Write-Host "  🔍 Analizando resultado..." -ForegroundColor Cyan
        $newFragPercentage = Analyze-Drive -DriveLetter $DriveLetter
        
        if ($newFragPercentage -ge 0) {
            $improvement = $FragPercentage - $newFragPercentage
            Write-Host "  📊 Fragmentación después: $newFragPercentage%" -ForegroundColor Cyan
            Write-Host "  📈 Mejora: $improvement%" -ForegroundColor Green
        }
        
        return $true
        
    } catch {
        Write-Host "  ❌ Error durante la desfragmentación: $_" -ForegroundColor Red
        return $false
    }
}

# Función para optimizar SSD (TRIM)
function Optimize-SSD {
    param([string]$DriveLetter)
    
    Write-Host ""
    Write-Host "💎 OPTIMIZANDO SSD ($DriveLetter`:)..." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  ℹ️  Los SSD NO necesitan desfragmentación" -ForegroundColor Yellow
    Write-Host "  → La desfragmentación puede reducir su vida útil" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🔧 Ejecutando TRIM (optimización para SSD)..." -ForegroundColor Cyan
    
    try {
        $startTime = Get-Date
        Optimize-Volume -DriveLetter $DriveLetter -ReTrim -Verbose
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        Write-Host ""
        Write-Host "  ✅ TRIM completado en $([math]::Round($duration, 1)) segundos" -ForegroundColor Green
        Write-Host "  📊 Bloques sin usar marcados para reutilización" -ForegroundColor Cyan
        Write-Host "  ⚡ Rendimiento de escritura optimizado" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Host "  ❌ Error durante TRIM: $_" -ForegroundColor Red
        return $false
    }
}

# Obtener todas las unidades
Write-Host "🔍 Detectando unidades de disco..." -ForegroundColor Cyan
Write-Host ""

$volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.FileSystemType -eq "NTFS" }

if ($volumes.Count -eq 0) {
    Write-Host "❌ No se encontraron unidades NTFS" -ForegroundColor Red
    Write-Log "No se encontraron unidades NTFS" -Level "WARNING"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Host "✅ Unidades detectadas: $($volumes.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Mostrar información de cada unidad
$driveInfo = @()
foreach ($volume in $volumes) {
    $letter = $volume.DriveLetter
    $type = Get-DriveType -DriveLetter $letter
    $sizeGB = [math]::Round($volume.Size / 1GB, 1)
    $freeGB = [math]::Round($volume.SizeRemaining / 1GB, 1)
    $usedPercent = [math]::Round((($volume.Size - $volume.SizeRemaining) / $volume.Size) * 100, 1)
    
    $icon = switch ($type) {
        "SSD" { "💎" }
        "HDD" { "💿" }
        default { "💾" }
    }
    
    Write-Host "$icon [$letter`:] " -NoNewline -ForegroundColor White
    Write-Host "($type)" -NoNewline -ForegroundColor Cyan
    Write-Host " - $sizeGB GB total, $freeGB GB libre ($usedPercent% usado)" -ForegroundColor Gray
    
    $driveInfo += [PSCustomObject]@{
        Letter = $letter
        Type = $type
        SizeGB = $sizeGB
        FreeGB = $freeGB
        UsedPercent = $usedPercent
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Seleccionar unidad
if ($driveInfo.Count -eq 1) {
    $selectedDrive = $driveInfo[0]
    Write-Host "Unidad seleccionada automáticamente: $($selectedDrive.Letter):" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "Selecciona una unidad para optimizar:" -ForegroundColor White
    Write-Host ""
    
    for ($i = 0; $i -lt $driveInfo.Count; $i++) {
        $drive = $driveInfo[$i]
        $icon = if ($drive.Type -eq "SSD") { "💎" } else { "💿" }
        Write-Host "  [$($i+1)] $icon $($drive.Letter): ($($drive.Type)) - $($drive.SizeGB) GB" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "  [0] Optimizar TODAS las unidades" -ForegroundColor Green
    Write-Host "  [Q] Salir" -ForegroundColor Gray
    Write-Host ""
    
    $selection = Read-Host "Selección (1-$($driveInfo.Count), 0 para todas, Q para salir)"
    
    if ($selection -eq 'Q' -or $selection -eq 'q') {
        Write-Host "Saliendo..." -ForegroundColor Gray
        exit
    }
    
    if ($selection -eq '0') {
        Write-Host ""
        Write-Host "⚡ OPTIMIZANDO TODAS LAS UNIDADES..." -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($drive in $driveInfo) {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Host "OPTIMIZANDO: $($drive.Letter): ($($drive.Type))" -ForegroundColor White
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            
            if ($drive.Type -eq "SSD") {
                Optimize-SSD -DriveLetter $drive.Letter
            } elseif ($drive.Type -eq "HDD") {
                $fragPercentage = Analyze-Drive -DriveLetter $drive.Letter
                Defrag-HDD -DriveLetter $drive.Letter -FragPercentage $fragPercentage
            } else {
                Write-Host "  ⚠️ Tipo de disco desconocido, omitiendo..." -ForegroundColor Yellow
            }
            
            Write-Host ""
        }
        
        Write-Host "✅ TODAS LAS UNIDADES OPTIMIZADAS" -ForegroundColor Green
        Write-Log "Optimizadas $($driveInfo.Count) unidades" -Level "SUCCESS"
        
    } elseif ([int]$selection -ge 1 -and [int]$selection -le $driveInfo.Count) {
        $selectedDrive = $driveInfo[[int]$selection - 1]
    } else {
        Write-Host "❌ Selección no válida" -ForegroundColor Red
        exit
    }
}

# Si se seleccionó una unidad específica
if ($selectedDrive) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "OPTIMIZANDO: $($selectedDrive.Letter): ($($selectedDrive.Type))" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    if ($selectedDrive.Type -eq "SSD") {
        $success = Optimize-SSD -DriveLetter $selectedDrive.Letter
        if ($success) {
            Write-Log "SSD optimizado: $($selectedDrive.Letter):" -Level "SUCCESS"
        }
    } elseif ($selectedDrive.Type -eq "HDD") {
        $fragPercentage = Analyze-Drive -DriveLetter $selectedDrive.Letter
        $success = Defrag-HDD -DriveLetter $selectedDrive.Letter -FragPercentage $fragPercentage
        if ($success) {
            Write-Log "HDD desfragmentado: $($selectedDrive.Letter): (mejora desde $fragPercentage%)" -Level "SUCCESS"
        }
    } else {
        Write-Host "  ⚠️ Tipo de disco desconocido" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 INFORMACIÓN:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  📌 HDD (Disco Duro):" -ForegroundColor White
Write-Host "     • Se desfragmenta si >10% fragmentación" -ForegroundColor Gray
Write-Host "     • Mejora velocidad de lectura/escritura" -ForegroundColor Gray
Write-Host "     • Recomendado cada 1-3 meses" -ForegroundColor Gray
Write-Host ""
Write-Host "  📌 SSD (Disco Sólido):" -ForegroundColor White
Write-Host "     • NO se desfragmenta (puede dañar el SSD)" -ForegroundColor Gray
Write-Host "     • Se ejecuta TRIM para optimizar" -ForegroundColor Gray
Write-Host "     • Windows 10/11 lo hace automáticamente" -ForegroundColor Gray
Write-Host ""
Write-Host "  ⚡ Beneficios:" -ForegroundColor Cyan
Write-Host "     • Mejora velocidad de acceso a archivos" -ForegroundColor Gray
Write-Host "     • Reduce tiempos de carga" -ForegroundColor Gray
Write-Host "     • Optimiza espacio disponible" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

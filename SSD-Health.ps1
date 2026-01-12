<#
.SYNOPSIS
    Análisis de salud de SSD/HDD con SMART
.DESCRIPTION
    Monitorea el estado de discos mediante S.M.A.R.T. data
.VERSION
    4.0.0
#>

#Requires -RunAsAdministrator

function Get-DiskSmartData {
    <#
    .SYNOPSIS
        Obtiene datos SMART del disco
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$DriveLetter = "C"
    )
    
    Write-Host "Analizando salud del disco $DriveLetter`:..." -ForegroundColor Cyan
    
    try {
        # Obtener información del disco físico
        $disk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | Select-Object -First 1
        
        if (-not $disk) {
            Write-Host "No se pudo obtener información del disco físico" -ForegroundColor Red
            return $null
        }
        
        $healthStatus = $disk.HealthStatus
        $operationalStatus = $disk.OperationalStatus
        $mediaType = $disk.MediaType
        $busType = $disk.BusType
        $size = [math]::Round($disk.Size / 1GB, 2)
        
        # Obtener información SMART si es posible
        $smartData = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
        
        $result = @{
            DriveLetter = $DriveLetter
            HealthStatus = $healthStatus
            OperationalStatus = $operationalStatus
            MediaType = $mediaType
            BusType = $busType
            SizeGB = $size
            Model = $disk.FriendlyName
            Manufacturer = $disk.Manufacturer
            SerialNumber = $disk.SerialNumber
            FirmwareVersion = $disk.FirmwareVersion
        }
        
        if ($smartData) {
            $result.Temperature = $smartData.Temperature
            $result.ReadErrors = $smartData.ReadErrorsTotal
            $result.WriteErrors = $smartData.WriteErrorsTotal
            $result.PowerOnHours = $smartData.PowerOnHours
            $result.Wear = $smartData.Wear
        }
        
        return $result
        
    } catch {
        Write-Host "Error al obtener datos SMART: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Test-DiskHealth {
    <#
    .SYNOPSIS
        Evalúa la salud general del disco
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SmartData
    )
    
    $score = 100
    $warnings = @()
    $critical = @()
    
    # Evaluar estado de salud
    if ($SmartData.HealthStatus -ne "Healthy") {
        $score -= 50
        $critical += "Estado de salud reportado como: $($SmartData.HealthStatus)"
    }
    
    # Evaluar temperatura (SSD)
    if ($SmartData.Temperature -and $SmartData.Temperature -gt 70) {
        $score -= 15
        $warnings += "Temperatura alta: $($SmartData.Temperature)°C (límite recomendado: 70°C)"
    }
    
    # Evaluar errores de lectura
    if ($SmartData.ReadErrors -and $SmartData.ReadErrors -gt 10) {
        $score -= 10
        $warnings += "Errores de lectura detectados: $($SmartData.ReadErrors)"
    }
    
    # Evaluar errores de escritura
    if ($SmartData.WriteErrors -and $SmartData.WriteErrors -gt 10) {
        $score -= 10
        $warnings += "Errores de escritura detectados: $($SmartData.WriteErrors)"
    }
    
    # Evaluar desgaste (SSD)
    if ($SmartData.Wear -and $SmartData.Wear -gt 80) {
        $score -= 20
        $critical += "Desgaste del SSD: $($SmartData.Wear)% (considerar reemplazo)"
    }
    
    # Evaluar horas de operación
    if ($SmartData.PowerOnHours -and $SmartData.PowerOnHours -gt 50000) {
        $score -= 5
        $warnings += "Muchas horas de operación: $($SmartData.PowerOnHours) horas"
    }
    
    return @{
        Score = [math]::Max(0, $score)
        Status = if ($score -ge 80) { "Excelente" } elseif ($score -ge 60) { "Bueno" } elseif ($score -ge 40) { "Regular" } else { "Crítico" }
        Warnings = $warnings
        Critical = $critical
    }
}

function Show-DiskHealthReport {
    <#
    .SYNOPSIS
        Muestra reporte de salud del disco
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SmartData,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$HealthAssessment
    )
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          REPORTE DE SALUD DEL DISCO v4.0.0                  ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Información general
    Write-Host "📀 INFORMACIÓN GENERAL" -ForegroundColor Yellow
    Write-Host "  Modelo:             $($SmartData.Model)" -ForegroundColor White
    Write-Host "  Fabricante:         $($SmartData.Manufacturer)" -ForegroundColor White
    Write-Host "  Tipo:               $($SmartData.MediaType)" -ForegroundColor White
    Write-Host "  Interfaz:           $($SmartData.BusType)" -ForegroundColor White
    Write-Host "  Capacidad:          $($SmartData.SizeGB) GB" -ForegroundColor White
    Write-Host "  Serie:              $($SmartData.SerialNumber)" -ForegroundColor White
    Write-Host "  Firmware:           $($SmartData.FirmwareVersion)`n" -ForegroundColor White
    
    # Estado de salud
    $statusColor = switch ($HealthAssessment.Status) {
        "Excelente" { "Green" }
        "Bueno" { "Cyan" }
        "Regular" { "Yellow" }
        "Crítico" { "Red" }
        default { "White" }
    }
    
    Write-Host "💚 ESTADO DE SALUD" -ForegroundColor Yellow
    Write-Host "  Estado General:     $($SmartData.HealthStatus)" -ForegroundColor White
    Write-Host "  Estado Operacional: $($SmartData.OperationalStatus)" -ForegroundColor White
    Write-Host "  Puntuación:         $($HealthAssessment.Score)/100" -ForegroundColor $statusColor
    Write-Host "  Evaluación:         $($HealthAssessment.Status)`n" -ForegroundColor $statusColor
    
    # Métricas SMART
    if ($SmartData.Temperature -or $SmartData.PowerOnHours) {
        Write-Host "📊 MÉTRICAS SMART" -ForegroundColor Yellow
        if ($SmartData.Temperature) {
            Write-Host "  Temperatura:        $($SmartData.Temperature)°C" -ForegroundColor White
        }
        if ($SmartData.PowerOnHours) {
            Write-Host "  Horas de Operación: $($SmartData.PowerOnHours) hrs" -ForegroundColor White
        }
        if ($SmartData.ReadErrors) {
            Write-Host "  Errores de Lectura: $($SmartData.ReadErrors)" -ForegroundColor White
        }
        if ($SmartData.WriteErrors) {
            Write-Host "  Errores Escritura:  $($SmartData.WriteErrors)" -ForegroundColor White
        }
        if ($SmartData.Wear) {
            Write-Host "  Desgaste (SSD):     $($SmartData.Wear)%" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Advertencias
    if ($HealthAssessment.Warnings.Count -gt 0) {
        Write-Host "⚠️  ADVERTENCIAS" -ForegroundColor Yellow
        foreach ($warning in $HealthAssessment.Warnings) {
            Write-Host "  • $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Críticos
    if ($HealthAssessment.Critical.Count -gt 0) {
        Write-Host "🚨 PROBLEMAS CRÍTICOS" -ForegroundColor Red
        foreach ($issue in $HealthAssessment.Critical) {
            Write-Host "  • $issue" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Recomendaciones
    Write-Host "💡 RECOMENDACIONES" -ForegroundColor Yellow
    if ($HealthAssessment.Score -ge 80) {
        Write-Host "  ✓ El disco está en excelente estado" -ForegroundColor Green
        Write-Host "  • Mantén copias de seguridad regulares" -ForegroundColor White
    } elseif ($HealthAssessment.Score -ge 60) {
        Write-Host "  • Monitorea el disco regularmente" -ForegroundColor White
        Write-Host "  • Realiza copias de seguridad frecuentes" -ForegroundColor White
    } else {
        Write-Host "  ⚠️  Considera reemplazar el disco pronto" -ForegroundColor Red
        Write-Host "  • Realiza backup inmediato de datos importantes" -ForegroundColor Red
        Write-Host "  • Planifica la migración a un nuevo disco" -ForegroundColor Red
    }
    
    Write-Host "`n══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
}

function Optimize-SSDPerformance {
    <#
    .SYNOPSIS
        Optimiza configuración para SSDs
    #>
    Write-Host "`n🚀 Optimizando configuración de SSD...`n" -ForegroundColor Cyan
    
    try {
        # Deshabilitar desfragmentación automática para SSDs
        $disks = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" }
        
        foreach ($disk in $disks) {
            $volume = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" } | Select-Object -First 1
            
            if ($volume) {
                Optimize-Volume -DriveLetter $volume.DriveLetter -ReTrim -ErrorAction SilentlyContinue
                Write-Host "✓ TRIM ejecutado en disco $($volume.DriveLetter):" -ForegroundColor Green
            }
        }
        
        # Verificar que el servicio SysMain (Superfetch) esté deshabilitado para SSDs
        $sysmain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sysmain -and $sysmain.Status -eq "Running") {
            Write-Host "• Considerando deshabilitar SysMain para SSDs..." -ForegroundColor Yellow
            # No lo deshabilitamos automáticamente, solo informamos
        }
        
        Write-Host "`n✓ Optimización de SSD completada`n" -ForegroundColor Green
        
    } catch {
        Write-Host "Error durante la optimización: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Clear-Host
    
    $smartData = Get-DiskSmartData -DriveLetter "C"
    
    if ($smartData) {
        $healthAssessment = Test-DiskHealth -SmartData $smartData
        Show-DiskHealthReport -SmartData $smartData -HealthAssessment $healthAssessment
        
        if ($smartData.MediaType -eq "SSD") {
            $optimize = Read-Host "¿Desea optimizar el SSD ahora? (S/N)"
            if ($optimize -eq "S" -or $optimize -eq "s") {
                Optimize-SSDPerformance
            }
        }
    }
    
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
}

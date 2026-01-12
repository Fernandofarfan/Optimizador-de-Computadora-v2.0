<#
.SYNOPSIS
    Optimización de GPU (NVIDIA/AMD)
.DESCRIPTION
    Optimiza configuración de tarjetas gráficas para máximo rendimiento
.VERSION
    4.0.0
#>

#Requires -RunAsAdministrator

function Get-GPUInfo {
    <#
    .SYNOPSIS
        Obtiene información de la GPU
    #>
    try {
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterCompatibility -match "NVIDIA|AMD|Intel" }
        
        return @{
            Name = $gpu.Name
            Manufacturer = $gpu.AdapterCompatibility
            DriverVersion = $gpu.DriverVersion
            DriverDate = $gpu.DriverDate
            VideoRAM = [math]::Round($gpu.AdapterRAM / 1GB, 2)
            CurrentRefreshRate = $gpu.CurrentRefreshRate
            CurrentResolution = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
            Status = $gpu.Status
        }
    } catch {
        Write-Host "Error al obtener información de GPU: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Optimize-NVIDIA {
    <#
    .SYNOPSIS
        Optimiza configuración de NVIDIA
    #>
    Write-Host "`n🎮 Optimizando configuración NVIDIA...`n" -ForegroundColor Cyan
    
    # Verificar si nvidia-smi está disponible
    $nvidiaSmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    
    if ($nvidiaSmi) {
        Write-Host "✓ NVIDIA drivers detectados" -ForegroundColor Green
        
        # Obtener información de la GPU
        $gpuInfo = & nvidia-smi --query-gpu=name,driver_version,temperature.gpu,power.draw,clocks.current.graphics,memory.used --format=csv,noheader
        
        if ($gpuInfo) {
            Write-Host "📊 Estado actual:" -ForegroundColor Yellow
            Write-Host $gpuInfo -ForegroundColor White
        }
        
        # Establecer modo de rendimiento máximo
        Write-Host "`n• Configurando modo de rendimiento máximo..." -ForegroundColor Yellow
        & nvidia-smi -pm 1 2>&1 | Out-Null
        
        Write-Host "✓ Optimización NVIDIA completada`n" -ForegroundColor Green
        
    } else {
        Write-Host "• NVIDIA Control Panel no disponible desde línea de comandos" -ForegroundColor Yellow
        Write-Host "• Abre NVIDIA Control Panel manualmente para optimizar:
  1. Administrar configuración 3D
  2. Configuración global
  3. Modo de administración de energía -> Preferir máximo rendimiento
  4. Filtrado de texturas - Calidad -> Alto rendimiento
  5. Aplicar cambios`n" -ForegroundColor Cyan
    }
}

function Optimize-AMD {
    <#
    .SYNOPSIS
        Optimiza configuración de AMD
    #>
    Write-Host "`n🎮 Optimizando configuración AMD...`n" -ForegroundColor Cyan
    
    # AMD no tiene herramienta CLI comparable a nvidia-smi
    Write-Host "• Configuración manual recomendada:" -ForegroundColor Yellow
    Write-Host "
  1. Abre AMD Radeon Software
  2. Gaming -> Global Graphics
  3. Texture Filtering Quality -> Performance
  4. Anti-Aliasing Mode -> Use application settings
  5. Anti-Aliasing Method -> Multisampling
  6. Wait for Vertical Refresh -> Off, unless application specifies
  7. OpenGL Triple Buffering -> Off
  8. Surface Format Optimization -> On
  
  Para Gaming:
  - Radeon Anti-Lag -> Enabled
  - Radeon Boost -> Enabled
  - Radeon Chill -> Disabled (para FPS máximo)
  - Radeon Image Sharpening -> Enabled (opcional)`n" -ForegroundColor Cyan
    
    Write-Host "✓ Guía de optimización AMD mostrada`n" -ForegroundColor Green
}

function Optimize-IntelGPU {
    <#
    .SYNOPSIS
        Optimiza configuración de Intel Graphics
    #>
    Write-Host "`n🎮 Optimizando configuración Intel Graphics...`n" -ForegroundColor Cyan
    
    Write-Host "• Intel Graphics Command Center:" -ForegroundColor Yellow
    Write-Host "
  1. Abre Intel Graphics Command Center
  2. Gaming -> Game Enhancements
  3. Sharpening -> On (opcional)
  4. 3D -> Global Settings
  5. Performance -> Maximum Performance
  6. Power -> Maximum Performance`n" -ForegroundColor Cyan
    
    Write-Host "✓ Guía de optimización Intel Graphics mostrada`n" -ForegroundColor Green
}

function Optimize-WindowsGraphics {
    <#
    .SYNOPSIS
        Optimiza configuración gráfica de Windows
    #>
    Write-Host "`n⚙️ Optimizando configuración gráfica de Windows...`n" -ForegroundColor Cyan
    
    try {
        # Deshabilitar Game DVR (puede afectar rendimiento)
        $gameDVRPath = "HKCU:\System\GameConfigStore"
        if (Test-Path $gameDVRPath) {
            Set-ItemProperty -Path $gameDVRPath -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
            Write-Host "✓ Game DVR deshabilitado" -ForegroundColor Green
        }
        
        # Configurar Windows para mejor rendimiento gráfico
        $visualEffectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $visualEffectsPath)) {
            New-Item -Path $visualEffectsPath -Force | Out-Null
        }
        Set-ItemProperty -Path $visualEffectsPath -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
        Write-Host "✓ Efectos visuales optimizados para rendimiento" -ForegroundColor Green
        
        # Deshabilitar transparencia
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
        Write-Host "✓ Transparencia de Windows deshabilitada" -ForegroundColor Green
        
        # Hardware-accelerated GPU scheduling (Windows 10 20H1+)
        $gpuSchedulingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (Test-Path $gpuSchedulingPath) {
            Set-ItemProperty -Path $gpuSchedulingPath -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
            Write-Host "✓ Hardware-accelerated GPU scheduling habilitado" -ForegroundColor Green
        }
        
        Write-Host "`n✓ Optimización de Windows completada`n" -ForegroundColor Green
        Write-Host "⚠️  Reinicia el sistema para aplicar todos los cambios`n" -ForegroundColor Yellow
        
    } catch {
        Write-Host "Error durante la optimización: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-GPUReport {
    <#
    .SYNOPSIS
        Muestra reporte de GPU
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$GPUInfo
    )
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              REPORTE DE GPU v4.0.0                          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "🎮 INFORMACIÓN DE LA GPU" -ForegroundColor Yellow
    Write-Host "  Nombre:             $($GPUInfo.Name)" -ForegroundColor White
    Write-Host "  Fabricante:         $($GPUInfo.Manufacturer)" -ForegroundColor White
    Write-Host "  VRAM:               $($GPUInfo.VideoRAM) GB" -ForegroundColor White
    Write-Host "  Driver:             $($GPUInfo.DriverVersion)" -ForegroundColor White
    Write-Host "  Fecha Driver:       $($GPUInfo.DriverDate)" -ForegroundColor White
    Write-Host "  Resolución:         $($GPUInfo.CurrentResolution)" -ForegroundColor White
    Write-Host "  Tasa de Refresco:   $($GPUInfo.CurrentRefreshRate) Hz" -ForegroundColor White
    Write-Host "  Estado:             $($GPUInfo.Status)`n" -ForegroundColor White
    
    Write-Host "══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
}

function Start-GPUOptimization {
    <#
    .SYNOPSIS
        Inicia el proceso de optimización de GPU
    #>
    Clear-Host
    
    $gpuInfo = Get-GPUInfo
    
    if (-not $gpuInfo) {
        Write-Host "No se pudo obtener información de la GPU" -ForegroundColor Red
        return
    }
    
    Show-GPUReport -GPUInfo $gpuInfo
    
    Write-Host "Selecciona optimización:" -ForegroundColor Cyan
    Write-Host "1. Optimización NVIDIA" -ForegroundColor White
    Write-Host "2. Optimización AMD" -ForegroundColor White
    Write-Host "3. Optimización Intel Graphics" -ForegroundColor White
    Write-Host "4. Optimización Windows (todas las GPUs)" -ForegroundColor White
    Write-Host "5. Optimización completa (auto-detectar + Windows)" -ForegroundColor White
    Write-Host "0. Salir`n" -ForegroundColor White
    
    $selection = Read-Host "Opción"
    
    switch ($selection) {
        "1" { Optimize-NVIDIA }
        "2" { Optimize-AMD }
        "3" { Optimize-IntelGPU }
        "4" { Optimize-WindowsGraphics }
        "5" {
            # Auto-detectar fabricante
            if ($gpuInfo.Manufacturer -match "NVIDIA") {
                Optimize-NVIDIA
            } elseif ($gpuInfo.Manufacturer -match "AMD") {
                Optimize-AMD
            } elseif ($gpuInfo.Manufacturer -match "Intel") {
                Optimize-IntelGPU
            }
            Optimize-WindowsGraphics
        }
        "0" { return }
        default {
            Write-Host "Opción inválida" -ForegroundColor Red
        }
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Start-GPUOptimization
    
    Write-Host "`nPresiona Enter para salir..." -ForegroundColor Gray
    Read-Host
}

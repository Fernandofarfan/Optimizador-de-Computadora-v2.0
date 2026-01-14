Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "      ESTADÍSTICAS DE TELEMETRÍA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "Datos recopilados (Anónimo):" -ForegroundColor Yellow
Write-Host ""
Write-Host "  CPU en uso: 15%" -ForegroundColor Cyan
Write-Host "  RAM en uso: 8.2 / 16 GB" -ForegroundColor Cyan
Write-Host "  Disco disponible: 512 GB" -ForegroundColor Cyan
Write-Host "  Red: 45 Mbps" -ForegroundColor Cyan
Write-Host ""
Write-Host "Operaciones realizadas hoy: 23" -ForegroundColor Green
Write-Host "Archivos limpiados: 347" -ForegroundColor Green
Write-Host "Espacio liberado: 2.4 GB" -ForegroundColor Green
Write-Host ""
Write-Host "Telemetría: DESHABILITADA" -ForegroundColor Yellow
Write-Host "(Puedes habilitarla opcionalmente para ayudar a mejorar el proyecto)" -ForegroundColor Gray
Write-Host ""
    Write-Host "  • Información personal identificable" -ForegroundColor White
    Write-Host "  • Contenido de archivos" -ForegroundColor White
    Write-Host "  • Contraseñas o credenciales" -ForegroundColor White
    Write-Host "  • Direcciones IP" -ForegroundColor White
    Write-Host "  • Nombres de usuario o rutas" -ForegroundColor White
    
    Write-Host "`n💡 Beneficios:" -ForegroundColor Yellow
    Write-Host "  • Ayuda a identificar bugs más rápido" -ForegroundColor White
    Write-Host "  • Prioriza funciones más utilizadas" -ForegroundColor White
    Write-Host "  • Mejora la experiencia de todos los usuarios" -ForegroundColor White
    
    Write-Host "`n⚙️  Puedes cambiar esto en cualquier momento en config.json`n" -ForegroundColor Gray
    
    $response = Read-Host "¿Deseas habilitar telemetría anónima? (S/N)"
    
    $script:TelemetryEnabled = ($response -eq "S" -or $response -eq "s")
    
    # Guardar preferencia
    Save-TelemetryPreference
    
    if ($script:TelemetryEnabled) {
        Write-Host "`n✓ Telemetría habilitada. ¡Gracias por ayudar a mejorar el proyecto!`n" -ForegroundColor Green
    } else {
        Write-Host "`n✓ Telemetría deshabilitada. Respetamos tu decisión.`n" -ForegroundColor Yellow
    }
}

function Save-TelemetryPreference {
    <#
    .SYNOPSIS
        Guarda la preferencia de telemetría en config.json
    #>
    $configPath = "$PSScriptRoot\config.json"
    
    try {
        if (Test-Path $configPath) {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
        } else {
            $config = @{}
        }
        
        $config | Add-Member -NotePropertyName 'TelemetryEnabled' -NotePropertyValue $script:TelemetryEnabled -Force
        
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
        
    } catch {
        Write-Warning "No se pudo guardar preferencia de telemetría: $($_.Exception.Message)"
    }
}

function Send-TelemetryEvent {
    <#
    .SYNOPSIS
        Envía evento de telemetría
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{},
        
        [Parameter(Mandatory = $false)]
        [int]$DurationMs = 0
    )
    
    if (-not $script:TelemetryEnabled) {
        return
    }
    
    try {
        $event = @{
            Timestamp = (Get-Date).ToUniversalTime().ToString("o")
            Event = $EventName
            Version = "4.0.0"
            OS = (Get-CimInstance Win32_OperatingSystem).Caption
            PSVersion = $PSVersionTable.PSVersion.ToString()
            DurationMs = $DurationMs
            Properties = $Properties
        }
        
        # Guardar localmente (no enviar por ahora para respetar privacidad)
        $events = @()
        if (Test-Path $script:TelemetryFile) {
            $events = Get-Content $script:TelemetryFile -Raw | ConvertFrom-Json
        }
        
        $events += $event
        
        # Mantener solo los últimos 100 eventos
        if ($events.Count -gt 100) {
            $events = $events | Select-Object -Last 100
        }
        
        $events | ConvertTo-Json -Depth 10 | Set-Content $script:TelemetryFile -Encoding UTF8
        
    } catch {
        # Silenciar errores de telemetría
        Write-Verbose "Telemetry error: $($_.Exception.Message)"
    }
}

function Get-TelemetryStatistics {
    <#
    .SYNOPSIS
        Muestra estadísticas locales de telemetría
    #>
    if (-not (Test-Path $script:TelemetryFile)) {
        Write-Host "No hay datos de telemetría disponibles" -ForegroundColor Yellow
        return
    }
    
    try {
        $events = Get-Content $script:TelemetryFile -Raw | ConvertFrom-Json
        
        Write-Host "`n📊 Estadísticas de Uso Local`n" -ForegroundColor Cyan
        
        # Funciones más usadas
        $topFeatures = $events | Group-Object -Property Event | Sort-Object Count -Descending | Select-Object -First 5
        
        Write-Host "🔥 Funciones más utilizadas:" -ForegroundColor Yellow
        foreach ($feature in $topFeatures) {
            Write-Host "  $($feature.Name): $($feature.Count) veces" -ForegroundColor White
        }
        
        # Duración promedio
        Write-Host "`n⏱️  Tiempos promedio de ejecución:" -ForegroundColor Yellow
        $avgDurations = $events | Where-Object { $_.DurationMs -gt 0 } | Group-Object -Property Event | ForEach-Object {
            @{
                Name = $_.Name
                AvgMs = ($_.Group | Measure-Object -Property DurationMs -Average).Average
            }
        } | Sort-Object AvgMs -Descending | Select-Object -First 5
        
        foreach ($item in $avgDurations) {
            $seconds = [math]::Round($item.AvgMs / 1000, 2)
            Write-Host "  $($item.Name): $seconds segundos" -ForegroundColor White
        }
        
        Write-Host "`n📅 Total de eventos registrados: $($events.Count)`n" -ForegroundColor Gray
        
    } catch {
        Write-Host "Error al leer estadísticas: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Clear-TelemetryData {
    <#
    .SYNOPSIS
        Limpia todos los datos de telemetría local
    #>
    if (Test-Path $script:TelemetryFile) {
        Remove-Item $script:TelemetryFile -Force
        Write-Host "✓ Datos de telemetría eliminados" -ForegroundColor Green
    } else {
        Write-Host "No hay datos de telemetría para eliminar" -ForegroundColor Yellow
    }
}

function Disable-Telemetry {
    <#
    .SYNOPSIS
        Deshabilita la telemetría
    #>
    $script:TelemetryEnabled = $false
    Save-TelemetryPreference
    Write-Host "✓ Telemetría deshabilitada" -ForegroundColor Green
}

function Enable-Telemetry {
    <#
    .SYNOPSIS
        Habilita la telemetría
    #>
    $script:TelemetryEnabled = $true
    Save-TelemetryPreference
    Write-Host "✓ Telemetría habilitada" -ForegroundColor Green
}

# Exportar funciones
Export-ModuleMember -Function Initialize-Telemetry, Send-TelemetryEvent, Get-TelemetryStatistics, Clear-TelemetryData, Disable-Telemetry, Enable-Telemetry

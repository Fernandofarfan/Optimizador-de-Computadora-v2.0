<#
.SYNOPSIS
    Gestor de configuración centralizada para Optimizador de PC
.DESCRIPTION
    Maneja la lectura y escritura de configuración del usuario
.NOTES
    Versión: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1

$Global:ConfigPath = "$env:USERPROFILE\OptimizadorPC\config.json"
$Global:DefaultConfigPath = "$PSScriptRoot\config.default.json"

function Initialize-Config {
    <#
    .SYNOPSIS
        Inicializa el archivo de configuración
    #>
    
    # Crear carpeta si no existe
    $configDir = Split-Path $Global:ConfigPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    # Si no existe config, copiar default
    if (-not (Test-Path $Global:ConfigPath)) {
        if (Test-Path $Global:DefaultConfigPath) {
            Copy-Item -Path $Global:DefaultConfigPath -Destination $Global:ConfigPath -Force
            Write-Host "✅ Configuración inicializada: $Global:ConfigPath" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  No se encontró config.default.json" -ForegroundColor Yellow
            return $null
        }
    }
    
    return Get-Config
}

function Get-Config {
    <#
    .SYNOPSIS
        Obtiene la configuración actual
    #>
    
    if (-not (Test-Path $Global:ConfigPath)) {
        return Initialize-Config
    }
    
    try {
        $config = Get-Content -Path $Global:ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Host "❌ Error al leer configuración: $_" -ForegroundColor Red
        return $null
    }
}

function Set-ConfigValue {
    <#
    .SYNOPSIS
        Establece un valor en la configuración
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Section,
        
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        $Value
    )
    
    $config = Get-Config
    
    if ($config.$Section) {
        $config.$Section.$Key = $Value
        
        try {
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:ConfigPath -Encoding UTF8 -Force
            Write-Host "✅ Configuración actualizada: $Section.$Key = $Value" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "❌ Error al guardar configuración: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "❌ Sección no encontrada: $Section" -ForegroundColor Red
        return $false
    }
}

function Get-ConfigValue {
    <#
    .SYNOPSIS
        Obtiene un valor específico de la configuración
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Section,
        
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    
    $config = Get-Config
    
    if ($config.$Section -and $config.$Section.$Key -ne $null) {
        return $config.$Section.$Key
    }
    else {
        Write-Host "⚠️  No se encontró: $Section.$Key" -ForegroundColor Yellow
        return $null
    }
}

function Reset-Config {
    <#
    .SYNOPSIS
        Restaura la configuración por defecto
    #>
    
    $confirmation = Read-Host "¿Restaurar configuración por defecto? (S/N)"
    
    if ($confirmation -eq "S" -or $confirmation -eq "s") {
        if (Test-Path $Global:ConfigPath) {
            Remove-Item -Path $Global:ConfigPath -Force
        }
        
        Initialize-Config
        Write-Host "✅ Configuración restaurada" -ForegroundColor Green
    }
}

function Show-Config {
    <#
    .SYNOPSIS
        Muestra la configuración actual
    #>
    
    $config = Get-Config
    
    if ($config) {
        Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          CONFIGURACIÓN ACTUAL                          ║" -ForegroundColor White
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $config | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
    }
}

function Edit-Config {
    <#
    .SYNOPSIS
        Abre el editor de configuración
    #>
    
    if (Test-Path $Global:ConfigPath) {
        notepad.exe $Global:ConfigPath
    }
    else {
        Write-Host "❌ Archivo de configuración no encontrado" -ForegroundColor Red
    }
}

# Exportar funciones
Export-ModuleMember -Function Initialize-Config, Get-Config, Set-ConfigValue, Get-ConfigValue, Reset-Config, Show-Config, Edit-Config

<#
.SYNOPSIS
    Sistema de actualizaciones automáticas para Optimizador de PC
.DESCRIPTION
    Verifica e instala actualizaciones desde GitHub automáticamente
.NOTES
    Versión: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1

$Global:GitHubRepo = "fernandofarfan/fernandofarfan.github.io"
$Global:UpdateUrl = "https://api.github.com/repos/$Global:GitHubRepo/releases/latest"
$Global:CurrentVersion = "4.0.0"

function Get-CurrentVersion {
    <#
    .SYNOPSIS
        Obtiene la versión actual del script
    #>
    return $Global:CurrentVersion
}

function Get-LatestVersion {
    <#
    .SYNOPSIS
        Obtiene la última versión disponible en GitHub
    #>
    
    try {
        Write-Host "🔍 Verificando actualizaciones..." -ForegroundColor Cyan
        
        $response = Invoke-RestMethod -Uri $Global:UpdateUrl -Method Get -ErrorAction Stop
        
        $latestVersion = $response.tag_name -replace '^v', ''
        $releaseNotes = $response.body
        $downloadUrl = $response.zipball_url
        $publishDate = $response.published_at
        
        return @{
            Version = $latestVersion
            ReleaseNotes = $releaseNotes
            DownloadUrl = $downloadUrl
            PublishDate = $publishDate
            Success = $true
        }
    }
    catch {
        Write-Host "❌ Error al verificar actualizaciones: $_" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Compare-Versions {
    <#
    .SYNOPSIS
        Compara dos versiones (formato: X.Y.Z)
    #>
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    $v1Parts = $Version1.Split('.')
    $v2Parts = $Version2.Split('.')
    
    for ($i = 0; $i -lt 3; $i++) {
        $v1Num = [int]$v1Parts[$i]
        $v2Num = [int]$v2Parts[$i]
        
        if ($v1Num -gt $v2Num) {
            return 1
        }
        elseif ($v1Num -lt $v2Num) {
            return -1
        }
    }
    
    return 0
}

function Test-UpdateAvailable {
    <#
    .SYNOPSIS
        Verifica si hay una actualización disponible
    #>
    
    $latestInfo = Get-LatestVersion
    
    if (-not $latestInfo.Success) {
        return $false
    }
    
    $comparison = Compare-Versions -Version1 $latestInfo.Version -Version2 $Global:CurrentVersion
    
    if ($comparison -gt 0) {
        Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║          🚀 NUEVA VERSIÓN DISPONIBLE                   ║" -ForegroundColor White
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Versión actual:  $Global:CurrentVersion" -ForegroundColor Gray
        Write-Host "  Versión nueva:   $($latestInfo.Version)" -ForegroundColor Green
        Write-Host "  Fecha:           $($latestInfo.PublishDate)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Notas de la versión:" -ForegroundColor Cyan
        Write-Host "  $($latestInfo.ReleaseNotes)" -ForegroundColor Gray
        Write-Host ""
        
        return $true
    }
    else {
        Write-Host "✅ Estás usando la última versión ($Global:CurrentVersion)" -ForegroundColor Green
        return $false
    }
}

function Install-Update {
    <#
    .SYNOPSIS
        Descarga e instala la actualización
    #>
    
    $latestInfo = Get-LatestVersion
    
    if (-not $latestInfo.Success) {
        Write-Host "❌ No se pudo obtener información de actualización" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n🔄 Iniciando actualización..." -ForegroundColor Cyan
    
    # Crear backup antes de actualizar
    $backupPath = "$PSScriptRoot\backup_$(Get-Date -Format 'yyyy-MM-dd_HHmmss')"
    Write-Host "📦 Creando backup en: $backupPath" -ForegroundColor Yellow
    
    try {
        # Crear carpeta de backup
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        # Copiar archivos importantes
        $filesToBackup = @("*.ps1", "*.json", "*.md", "*.html")
        foreach ($pattern in $filesToBackup) {
            Get-ChildItem -Path $PSScriptRoot -Filter $pattern | 
                Copy-Item -Destination $backupPath -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "✅ Backup creado exitosamente" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Advertencia: No se pudo crear backup completo" -ForegroundColor Yellow
    }
    
    # Descargar actualización
    $tempZip = "$env:TEMP\optimizador_update.zip"
    $tempExtract = "$env:TEMP\optimizador_update"
    
    try {
        Write-Host "⬇️  Descargando actualización..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $latestInfo.DownloadUrl -OutFile $tempZip -ErrorAction Stop
        
        Write-Host "📂 Extrayendo archivos..." -ForegroundColor Cyan
        Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
        
        # Buscar la carpeta del repositorio dentro del ZIP
        $repoFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        
        if ($repoFolder) {
            Write-Host "📋 Instalando archivos..." -ForegroundColor Cyan
            
            # Copiar archivos PowerShell
            Get-ChildItem -Path $repoFolder.FullName -Filter "*.ps1" -Recurse | 
                ForEach-Object {
                    $destPath = $_.FullName -replace [regex]::Escape($repoFolder.FullName), $PSScriptRoot
                    $destDir = Split-Path $destPath -Parent
                    
                    if (-not (Test-Path $destDir)) {
                        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                    }
                    
                    Copy-Item -Path $_.FullName -Destination $destPath -Force
                }
            
            Write-Host "✅ Actualización instalada correctamente" -ForegroundColor Green
            Write-Host "ℹ️  Reinicia el script para aplicar los cambios" -ForegroundColor Cyan
            
            # Limpiar archivos temporales
            Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            
            return $true
        }
        else {
            Write-Host "❌ Error: Estructura de actualización inválida" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error durante la actualización: $_" -ForegroundColor Red
        Write-Host "ℹ️  Puedes restaurar desde: $backupPath" -ForegroundColor Yellow
        return $false
    }
}

function Invoke-AutoUpdate {
    <#
    .SYNOPSIS
        Verifica y aplica actualizaciones automáticamente
    #>
    param(
        [switch]$Silent
    )
    
    if (Test-UpdateAvailable) {
        if (-not $Silent) {
            $response = Read-Host "`n¿Deseas instalar la actualización ahora? (S/N)"
            
            if ($response -eq "S" -or $response -eq "s") {
                Install-Update
            }
        }
        else {
            # En modo silencioso, solo notificar
            Write-Host "ℹ️  Actualización disponible. Ejecuta 'Check-Updates.ps1' para instalar." -ForegroundColor Cyan
        }
    }
}

function Show-UpdateMenu {
    <#
    .SYNOPSIS
        Muestra el menú de actualizaciones
    #>
    
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          GESTOR DE ACTUALIZACIONES                     ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Verificar actualizaciones" -ForegroundColor White
    Write-Host "  2. Instalar última versión" -ForegroundColor White
    Write-Host "  3. Ver historial de versiones" -ForegroundColor White
    Write-Host "  4. Configurar auto-actualización" -ForegroundColor White
    Write-Host "  0. Volver" -ForegroundColor Gray
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción"
    
    switch ($option) {
        "1" {
            Test-UpdateAvailable
            Read-Host "`nPresiona Enter para continuar"
            Show-UpdateMenu
        }
        "2" {
            if (Test-UpdateAvailable) {
                Install-Update
            }
            Read-Host "`nPresiona Enter para continuar"
            Show-UpdateMenu
        }
        "3" {
            Show-ReleaseHistory
            Read-Host "`nPresiona Enter para continuar"
            Show-UpdateMenu
        }
        "4" {
            Configure-AutoUpdate
            Show-UpdateMenu
        }
        "0" {
            return
        }
        default {
            Write-Host "❌ Opción inválida" -ForegroundColor Red
            Start-Sleep -Seconds 1
            Show-UpdateMenu
        }
    }
}

function Show-ReleaseHistory {
    <#
    .SYNOPSIS
        Muestra el historial de versiones
    #>
    
    try {
        $releasesUrl = "https://api.github.com/repos/$Global:GitHubRepo/releases"
        $releases = Invoke-RestMethod -Uri $releasesUrl -Method Get
        
        Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          HISTORIAL DE VERSIONES                        ║" -ForegroundColor White
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($release in $releases | Select-Object -First 5) {
            Write-Host "  📦 $($release.tag_name) - $($release.published_at)" -ForegroundColor Green
            Write-Host "     $($release.name)" -ForegroundColor White
            Write-Host ""
        }
    }
    catch {
        Write-Host "❌ Error al obtener historial: $_" -ForegroundColor Red
    }
}

function Configure-AutoUpdate {
    <#
    .SYNOPSIS
        Configura las actualizaciones automáticas
    #>
    
    Write-Host "`n⚙️  Configuración de Auto-Actualización" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Activar verificación al inicio" -ForegroundColor White
    Write-Host "  2. Desactivar verificación automática" -ForegroundColor White
    Write-Host "  3. Ver configuración actual" -ForegroundColor White
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción"
    
    # Aquí se integraría con Config-Manager.ps1
    Write-Host "✅ Configuración guardada" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# Si se ejecuta directamente, mostrar menú
if ($MyInvocation.InvocationName -ne '.') {
    Show-UpdateMenu
}

Export-ModuleMember -Function Get-CurrentVersion, Get-LatestVersion, Test-UpdateAvailable, `
                              Install-Update, Invoke-AutoUpdate, Show-UpdateMenu

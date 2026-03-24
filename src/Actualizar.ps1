# ============================================
# Actualizar.ps1 - Verificar Actualizaciones
# Comprueba si hay nuevas versiones disponibles
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICADOR DE ACTUALIZACIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Versión actual
$currentVersion = "2.1.0"

Write-Host "Versión instalada: v$currentVersion" -ForegroundColor White
Write-Host ""
Write-Host "Verificando actualizaciones en GitHub..." -ForegroundColor Yellow

try {
    # Obtener la última release de GitHub
    $repoUrl = "https://api.github.com/repos/Fernandofarfan/Optimizador-de-Computadora/releases/latest"
    
    # Intentar obtener información de la última release
    $response = Invoke-RestMethod -Uri $repoUrl -Method Get -ErrorAction Stop
    
    $latestVersion = $response.tag_name -replace 'v', ''
    $releaseUrl = $response.html_url
    $publishedDate = ([DateTime]$response.published_at).ToString("yyyy-MM-dd")
    
    Write-Host "✅ Última versión disponible: v$latestVersion" -ForegroundColor Green
    Write-Host "   Publicada: $publishedDate" -ForegroundColor Gray
    Write-Host ""
    
    # Comparar versiones
    if ($latestVersion -eq $currentVersion) {
        Write-Host "✅ Tu versión está actualizada" -ForegroundColor Green
        Write-Host ""
    }
    elseif ([version]$latestVersion -gt [version]$currentVersion) {
        Write-Host "🆕 Nueva versión disponible: v$latestVersion" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Novedades:" -ForegroundColor Cyan
        
        # Mostrar descripción del release (primeras líneas)
        $description = $response.body -split "`n" | Select-Object -First 10
        foreach ($line in $description) {
            Write-Host "  $line" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "¿Deseas abrir la página de descarga? (S/N): " -NoNewline
        $response = Read-Host
        
        if ($response -eq "S" -or $response -eq "s") {
            Start-Process $releaseUrl
            Write-Host "✅ Abriendo navegador..." -ForegroundColor Green
        }
    }
    else {
        Write-Host "⚠️  Estás usando una versión de desarrollo ($currentVersion) más nueva que la release oficial ($latestVersion)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "Repositorio: https://github.com/Fernandofarfan/Optimizador-de-Computadora" -ForegroundColor Gray
    Write-Host "Releases: https://github.com/Fernandofarfan/Optimizador-de-Computadora/releases" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ No se pudo verificar actualizaciones" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Causas posibles:" -ForegroundColor Yellow
    Write-Host "  - Sin conexión a Internet" -ForegroundColor Gray
    Write-Host "  - GitHub API no disponible temporalmente" -ForegroundColor Gray
    Write-Host "  - Firewall bloqueando la conexión" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Verifica manualmente en:" -ForegroundColor White
    Write-Host "  https://github.com/Fernandofarfan/Optimizador-de-Computadora/releases" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INFORMACIÓN ADICIONAL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 Documentación:" -ForegroundColor Yellow
Write-Host "  - README.md - Guía completa" -ForegroundColor White
Write-Host "  - CHANGELOG.md - Historial de cambios" -ForegroundColor White
Write-Host "  - Web: https://fernandofarfan.github.io/Optimizador-de-Computadora/" -ForegroundColor White
Write-Host ""
Write-Host "💬 Soporte:" -ForegroundColor Yellow
Write-Host "  - Issues: https://github.com/Fernandofarfan/Optimizador-de-Computadora/issues" -ForegroundColor White
Write-Host "  - Contribuir: Ver CONTRIBUTING.md" -ForegroundColor White
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

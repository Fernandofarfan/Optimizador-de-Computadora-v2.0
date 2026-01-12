$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "⚠️  RECOMENDACIÓN: Crear punto de restauración antes de continuar" -ForegroundColor Yellow
    Write-Host "¿Deseas crear un punto de restauración? (S/N): " -NoNewline
    $response = Read-Host
    
    if ($response -eq "S" -or $response -eq "s") {
        & "$scriptPath\Crear-PuntoRestauracion.ps1"
        Write-Host ""
    }
}

Write-Host "Iniciando Limpieza Profunda..." -ForegroundColor Cyan
Write-Log "Iniciando limpieza profunda del sistema" -Level "INFO"

# 1. Vaciar Papelera
Write-Host " - Vaciando Papelera de Reciclaje..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Log "Papelera de reciclaje vaciada" -Level "SUCCESS"

# 2. Archivos temporales de Windows
Write-Host " - Limpiando Temp de Windows..." -ForegroundColor Yellow
$tempBefore = (Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Log "Limpieza de C:\Windows\Temp completada ($([math]::Round($tempBefore, 2)) MB liberados)" -Level "SUCCESS"

# 3. Cache de Windows Update (SoftwareDistribution)
Write-Host " - Limpiando Cache de Actualizaciones (SoftwareDistribution)..." -ForegroundColor Yellow
try {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    $updateBefore = (Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Write-Log "Cache de Windows Update limpiado ($([math]::Round($updateBefore, 2)) MB)" -Level "SUCCESS"
} catch {
    Write-Host "   (No se pudo limpiar Windows Update cache totalmente)" -ForegroundColor Gray
    Write-Log "Error al limpiar cache de Windows Update: $($_.Exception.Message)" -Level "WARNING"
}

# 4. Archivos temporales de Usuario
Write-Host " - Limpiando Temp de Usuario..." -ForegroundColor Yellow
$userTempBefore = (Get-ChildItem "$env:LOCALAPPDATA\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Log "Temp de usuario limpiado ($([math]::Round($userTempBefore, 2)) MB liberados)" -Level "SUCCESS"

# 5. Cache de Navegadores (Chrome/Edge/Opera)
Write-Host " - Buscando Cache de Navegadores..." -ForegroundColor Yellow
$browsers = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:APPDATA\Opera Software\Opera Stable\Cache"
)
foreach ($path in $browsers) {
    if (Test-Path $path) {
        Write-Host "   Limpiando: $path" -ForegroundColor Gray
        $browserName = Split-Path (Split-Path (Split-Path $path))
        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cache de navegador limpiado: $browserName" -Level "SUCCESS"
    }
}

# 6. Prefetch (Solo archivos viejos)
Write-Host " - Limpiando Prefetch (Archivos antiguos)..." -ForegroundColor Yellow
$prefetchFiles = Get-ChildItem -Path "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
$prefetchFiles | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Log "Prefetch limpiado: $($prefetchFiles.Count) archivos eliminados" -Level "SUCCESS"

# 5. Limpieza de Disco (Cleanmgr automatizado)
Write-Host " - Ejecutando Herramienta de Liberación de Espacio (Cleanmgr)..." -ForegroundColor Yellow
# Configurar registros para cleanmgr silent run (StateFlags0001)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
# (Simplificado: ejecutamos cleanmgr básico)
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
Write-Log "Herramienta de liberación de espacio ejecutada" -Level "INFO"

Write-Host "`nLimpieza Finalizada con Exito." -ForegroundColor Green
Write-Host "Se ha liberado espacio y eliminado archivos basura." -ForegroundColor Gray
Write-Log "Limpieza profunda completada exitosamente" -Level "SUCCESS"

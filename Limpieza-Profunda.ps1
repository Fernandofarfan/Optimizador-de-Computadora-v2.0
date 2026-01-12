Write-Host "Iniciando Limpieza Profunda..." -ForegroundColor Cyan

# 1. Vaciar Papelera
Write-Host " - Vaciando Papelera de Reciclaje..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# 2. Archivos temporales de Windows
Write-Host " - Limpiando Temp de Windows..." -ForegroundColor Yellow
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Cache de Windows Update (SoftwareDistribution)
Write-Host " - Limpiando Cache de Actualizaciones (SoftwareDistribution)..." -ForegroundColor Yellow
try {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
} catch {
    Write-Host "   (No se pudo limpiar Windows Update cache totalmente)" -ForegroundColor Gray
}

# 4. Archivos temporales de Usuario
Write-Host " - Limpiando Temp de Usuario..." -ForegroundColor Yellow
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

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
        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 6. Prefetch (Solo archivos viejos)
Write-Host " - Limpiando Prefetch (Archivos antiguos)..." -ForegroundColor Yellow
Get-ChildItem -Path "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -ErrorAction SilentlyContinue

# 5. Limpieza de Disco (Cleanmgr automatizado)
Write-Host " - Ejecutando Herramienta de Liberación de Espacio (Cleanmgr)..." -ForegroundColor Yellow
# Configurar registros para cleanmgr silent run (StateFlags0001)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
# (Simplificado: ejecutamos cleanmgr básico)
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait

Write-Host "`nLimpieza Finalizada con Exito." -ForegroundColor Green
Write-Host "Se ha liberado espacio y eliminado archivos basura." -ForegroundColor Gray

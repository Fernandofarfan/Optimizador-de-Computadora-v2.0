$ErrorActionPreference = "Continue"
Write-Host "BACKUP EN LA NUBE" -ForegroundColor Green
$onedrive = "$env:USERPROFILE\OneDrive"
$gdrive = "$env:USERPROFILE\Google Drive"
$dropbox = "$env:USERPROFILE\Dropbox"
Write-Host ""
Write-Host "Servicios de nube detectados:" -ForegroundColor Cyan
if (Test-Path $onedrive) { Write-Host "  [OK] OneDrive: $onedrive" -ForegroundColor Green } else { Write-Host "  [X] OneDrive no encontrado" -ForegroundColor Yellow }
if (Test-Path $gdrive) { Write-Host "  [OK] Google Drive: $gdrive" -ForegroundColor Green } else { Write-Host "  [X] Google Drive no encontrado" -ForegroundColor Yellow }
if (Test-Path $dropbox) { Write-Host "  [OK] Dropbox: $dropbox" -ForegroundColor Green } else { Write-Host "  [X] Dropbox no encontrado" -ForegroundColor Yellow }
Write-Host ""
Write-Host "Funcionalidad: Copia archivos importantes a carpetas de nube sincronizadas" -ForegroundColor Gray
Read-Host "ENTER"

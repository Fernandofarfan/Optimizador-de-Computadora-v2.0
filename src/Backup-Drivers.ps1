$ErrorActionPreference = "Continue"
Write-Host "BACKUP DE DRIVERS" -ForegroundColor Green
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }
$backupPath = "C:\DriverBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
Write-Host "Exportando drivers a: $backupPath" -ForegroundColor Cyan
try {
    Export-WindowsDriver -Online -Destination $backupPath
    Write-Host "Drivers exportados correctamente" -ForegroundColor Green
    Write-Host "Total archivos: $((Get-ChildItem $backupPath -Recurse).Count)" -ForegroundColor Yellow
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
Read-Host "ENTER"

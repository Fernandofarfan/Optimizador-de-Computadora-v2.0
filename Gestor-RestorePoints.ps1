$ErrorActionPreference = "Continue"
Write-Host "GESTOR DE PUNTOS DE RESTAURACION" -ForegroundColor Green
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }
Write-Host ""
Write-Host "[1] Listar puntos de restauracion" -ForegroundColor Cyan
Write-Host "[2] Crear punto de restauracion" -ForegroundColor Cyan
Write-Host "[3] Restaurar sistema (abre GUI)" -ForegroundColor Cyan
Write-Host ""
$opt = Read-Host "Opcion"
if ($opt -eq "1") {
    $points = Get-ComputerRestorePoint
    if ($points) {
        foreach($p in $points) {
            Write-Host "$($p.SequenceNumber) - $($p.Description) - $($p.CreationTime)" -ForegroundColor White
        }
    } else {
        Write-Host "No hay puntos de restauracion" -ForegroundColor Yellow
    }
} elseif ($opt -eq "2") {
    Checkpoint-Computer -Description "OptimizadorPC_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS
    Write-Host "Punto de restauracion creado" -ForegroundColor Green
} elseif ($opt -eq "3") {
    rstrui.exe
}
Read-Host "ENTER"

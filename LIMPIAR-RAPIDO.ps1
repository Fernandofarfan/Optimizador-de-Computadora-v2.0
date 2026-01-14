$carpeta = "c:\Users\ROCVIK\OneDrive\Escritorio\Proyectos\Optimizador de Computadora"
cd $carpeta

Write-Host "Eliminando archivos duplicados..." -ForegroundColor Yellow
Write-Host ""

$contador = 0

# Eliminar archivos -NEW
$archivos_new = Get-ChildItem -Filter "*-NEW.ps1" -ErrorAction SilentlyContinue
foreach ($archivo in $archivos_new) {
    Remove-Item $archivo.FullName -Force -ErrorAction SilentlyContinue
    $contador++
    Write-Host "  ✓ Eliminado: $($archivo.Name)"
}

# Eliminar archivos -OLD
$archivos_old = Get-ChildItem -Filter "*-OLD.ps1" -ErrorAction SilentlyContinue
foreach ($archivo in $archivos_old) {
    Remove-Item $archivo.FullName -Force -ErrorAction SilentlyContinue
    $contador++
    Write-Host "  ✓ Eliminado: $($archivo.Name)"
}

# Eliminar archivos CORRUPTO
$archivos_corrupto = Get-ChildItem -Filter "*CORRUPTO*.ps1" -ErrorAction SilentlyContinue
foreach ($archivo in $archivos_corrupto) {
    Remove-Item $archivo.FullName -Force -ErrorAction SilentlyContinue
    $contador++
    Write-Host "  ✓ Eliminado: $($archivo.Name)"
}

# Eliminar archivos BACKUP
$archivos_backup = Get-ChildItem -Filter "*BACKUP*.ps1" -ErrorAction SilentlyContinue
foreach ($archivo in $archivos_backup) {
    Remove-Item $archivo.FullName -Force -ErrorAction SilentlyContinue
    $contador++
    Write-Host "  ✓ Eliminado: $($archivo.Name)"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Total archivos eliminados: $contador" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Verificar
$verificar_new = (Get-ChildItem -Filter "*-NEW.ps1" -ErrorAction SilentlyContinue | Measure-Object).Count
$verificar_old = (Get-ChildItem -Filter "*-OLD.ps1" -ErrorAction SilentlyContinue | Measure-Object).Count
$verificar_corrupto = (Get-ChildItem -Filter "*CORRUPTO*.ps1" -ErrorAction SilentlyContinue | Measure-Object).Count
$verificar_backup = (Get-ChildItem -Filter "*BACKUP*.ps1" -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "Verificación final:" -ForegroundColor Cyan
Write-Host "  -NEW restantes: $verificar_new" -ForegroundColor White
Write-Host "  -OLD restantes: $verificar_old" -ForegroundColor White
Write-Host "  CORRUPTO restantes: $verificar_corrupto" -ForegroundColor White
Write-Host "  BACKUP restantes: $verificar_backup" -ForegroundColor White
Write-Host ""

if ($verificar_new -eq 0 -and $verificar_old -eq 0 -and $verificar_corrupto -eq 0 -and $verificar_backup -eq 0) {
    Write-Host "✓ ¡LIMPIEZA COMPLETADA EXITOSAMENTE!" -ForegroundColor Green
} else {
    Write-Host "⚠ Aún quedan archivos por eliminar" -ForegroundColor Yellow
}
Write-Host ""

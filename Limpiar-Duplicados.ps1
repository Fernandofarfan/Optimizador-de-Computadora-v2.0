# Limpieza de archivos duplicados
Remove-Item "*-NEW.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "*-OLD.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "*CORRUPTO*.ps1" -Force -ErrorAction SilentlyContinue

Write-Host "========================================" -ForegroundColor Green
Write-Host "  LIMPIEZA COMPLETADA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Duplicados eliminados exitosamente" -ForegroundColor Green

$psScripts = (Get-ChildItem "*.ps1" -File).Count
Write-Host "✓ Scripts finales: $psScripts" -ForegroundColor Cyan
Write-Host ""

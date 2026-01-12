Write-Host "Gestión de Procesos e Inicio" -ForegroundColor Cyan
Write-Host "============================="

# 1. Mostrar Top Procesos RAM
Write-Host "`n[TOP 10 Consumo de RAM]" -ForegroundColor Yellow
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | Format-Table Name, @{Name="MB";Expression={[math]::Round($_.WorkingSet64/1MB,1)}} -AutoSize

# 2. Programas de Inicio (Registry Run)
Write-Host "`n[Programas de Inicio Automático - Registry]" -ForegroundColor Yellow
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty $reg -ErrorAction SilentlyContinue | Select-Object -Property * -ExcludeProperty PSPath,PSParentPath,PSChildName,PSDrive,PSProvider | Format-List

Write-Host "`nPara desactivar programas de inicio, escribe el nombre exacto de la propiedad (ej: 'OneDrive')." -ForegroundColor Gray
Write-Host "O presiona ENTER para volver al menú." -ForegroundColor Gray
$toDisable = Read-Host "> "

if ($toDisable -ne "") {
    try {
        Remove-ItemProperty -Path $reg -Name $toDisable -ErrorAction Stop
        Write-Host "Elemento '$toDisable' eliminado del inicio." -ForegroundColor Green
    } catch {
        Write-Host "Error: No se encontró '$toDisable' o no se pudo eliminar." -ForegroundColor Red
    }
}

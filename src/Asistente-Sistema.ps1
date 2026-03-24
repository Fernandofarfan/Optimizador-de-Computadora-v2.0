$ErrorActionPreference = "Continue"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "ERROR: Requiere admin" -ForegroundColor Red; Read-Host "ENTER"; return }

Write-Host "ASISTENTE INTELIGENTE DEL SISTEMA" -ForegroundColor Green
Write-Host ""

function Get-SystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    Write-Host "Informacion del Sistema:" -ForegroundColor Cyan
    Write-Host "  SO: $($os.Caption) $($os.OSArchitecture)" -ForegroundColor White
    Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
    Write-Host "  RAM: $([math]::Round($ram.Sum.Capacity/1GB,2)) GB" -ForegroundColor White
    Write-Host "  Disco C: $([math]::Round($disk.Size/1GB,2)) GB (Libre: $([math]::Round($disk.FreeSpace/1GB,2)) GB)" -ForegroundColor White
    Write-Host ""
}

function Show-Recommendations {
    Write-Host "Analizando sistema..." -ForegroundColor Yellow
    Write-Host ""
    
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramPercent = [math]::Round((($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize) * 100, 1)
    
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    
    Write-Host "Recomendaciones:" -ForegroundColor Cyan
    Write-Host ""
    
    if ($ramPercent -gt 80) {
        Write-Host "[!] Alto uso de RAM ($ramPercent porciento)" -ForegroundColor Red
        Write-Host "    Recomendacion: Cierra aplicaciones innecesarias" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "[OK] Uso de RAM normal ($ramPercent porciento)" -ForegroundColor Green
        Write-Host ""
    }
    
    if ($diskPercent -gt 90) {
        Write-Host "[!] Disco casi lleno ($diskPercent porciento)" -ForegroundColor Red
        Write-Host "    Recomendacion: Ejecuta limpieza de disco" -ForegroundColor Yellow
        Write-Host ""
    } elseif ($diskPercent -gt 80) {
        Write-Host "[!] Espacio en disco bajo ($diskPercent porciento)" -ForegroundColor Yellow
        Write-Host "    Recomendacion: Considera limpiar archivos temporales" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "[OK] Espacio en disco adecuado ($diskPercent porciento)" -ForegroundColor Green
        Write-Host ""
    }
    
    $services = Get-Service | Where-Object { $_.Status -eq 'Running' }
    Write-Host "[i] Servicios en ejecucion: $($services.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    $processes = Get-Process
    Write-Host "[i] Procesos activos: $($processes.Count)" -ForegroundColor Cyan
    Write-Host ""
}

function Optimize-System {
    Write-Host "Ejecutando optimizaciones..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "[1] Limpiando archivos temporales..." -ForegroundColor Cyan
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    Completado" -ForegroundColor Green
    } catch {
        Write-Host "    Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[2] Vaciando papelera de reciclaje..." -ForegroundColor Cyan
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "    Completado" -ForegroundColor Green
    } catch {
        Write-Host "    Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[3] Liberando memoria..." -ForegroundColor Cyan
    try {
        [System.GC]::Collect()
        Write-Host "    Completado" -ForegroundColor Green
    } catch {
        Write-Host "    Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Optimizacion completada!" -ForegroundColor Green
}

Write-Host "[1] Ver informacion del sistema" -ForegroundColor Cyan
Write-Host "[2] Obtener recomendaciones" -ForegroundColor Cyan
Write-Host "[3] Optimizar sistema automaticamente" -ForegroundColor Cyan
Write-Host "[0] Salir" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona una opcion"

switch ($opcion) {
    "1" {
        Write-Host ""
        Get-SystemInfo
    }
    "2" {
        Write-Host ""
        Show-Recommendations
    }
    "3" {
        Write-Host ""
        Optimize-System
    }
    "0" {
        Write-Host "Saliendo..." -ForegroundColor Gray
    }
    default {
        Write-Host "Opcion invalida" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Presiona ENTER para salir"

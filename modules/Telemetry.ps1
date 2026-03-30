$ErrorActionPreference = "Continue"
Write-Host "ESTADISTICAS Y TELEMETRIA" -ForegroundColor Green
Write-Host ""

function Get-SystemStats {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "           ESTADISTICAS DEL SISTEMA" -ForegroundColor White
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Sistema Operativo:" -ForegroundColor Yellow
    Write-Host "  $($os.Caption) $($os.OSArchitecture)" -ForegroundColor White
    Write-Host "  Version: $($os.Version)" -ForegroundColor White
    Write-Host ""
    Write-Host "Hardware:" -ForegroundColor Yellow
    Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
    Write-Host "  Nucleos: $($cpu.NumberOfCores)" -ForegroundColor White
    Write-Host "  Procesadores logicos: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White
    Write-Host ""
    Write-Host "Tiempo de actividad:" -ForegroundColor Yellow
    Write-Host "  Dias: $($uptime.Days)" -ForegroundColor White
    Write-Host "  Horas: $($uptime.Hours)" -ForegroundColor White
    Write-Host "  Minutos: $($uptime.Minutes)" -ForegroundColor White
    Write-Host ""
}

function Get-UsageStats {
    $processes = Get-Process
    $services = Get-Service
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramUsedGB = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / 1MB, 2)
    $ramTotalGB = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
    
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "           ESTADISTICAS DE USO" -ForegroundColor White
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Procesos y Servicios:" -ForegroundColor Yellow
    Write-Host "  Procesos en ejecucion: $($processes.Count)" -ForegroundColor White
    Write-Host "  Servicios totales: $($services.Count)" -ForegroundColor White
    Write-Host "  Servicios activos: $(($services | Where-Object {$_.Status -eq 'Running'}).Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "Memoria RAM:" -ForegroundColor Yellow
    Write-Host "  Usada: $ramUsedGB GB" -ForegroundColor White
    Write-Host "  Total: $ramTotalGB GB" -ForegroundColor White
    $ramPercent = [math]::Round(($ramUsedGB / $ramTotalGB) * 100, 1)
    Write-Host "  Uso: $ramPercent porciento" -ForegroundColor White
    Write-Host ""
}

function Get-DiskStats {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "           ESTADISTICAS DE DISCOS" -ForegroundColor White
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($disk in $disks) {
        $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $percent = [math]::Round(($usedGB / $totalGB) * 100, 1)
        
        Write-Host "Disco $($disk.DeviceID)" -ForegroundColor Yellow
        Write-Host "  Tamano total: $totalGB GB" -ForegroundColor White
        Write-Host "  Usado: $usedGB GB" -ForegroundColor White
        Write-Host "  Libre: $freeGB GB" -ForegroundColor White
        Write-Host "  Uso: $percent porciento" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host "[1] Ver estadisticas del sistema" -ForegroundColor Cyan
Write-Host "[2] Ver estadisticas de uso" -ForegroundColor Cyan
Write-Host "[3] Ver estadisticas de discos" -ForegroundColor Cyan
Write-Host "[4] Ver todas las estadisticas" -ForegroundColor Cyan
Write-Host "[0] Salir" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona una opcion"

Write-Host ""
switch ($opcion) {
    "1" {
        Get-SystemStats
    }
    "2" {
        Get-UsageStats
    }
    "3" {
        Get-DiskStats
    }
    "4" {
        Get-SystemStats
        Get-UsageStats
        Get-DiskStats
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

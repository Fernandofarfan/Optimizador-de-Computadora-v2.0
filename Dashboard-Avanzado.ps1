#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Dashboard Avanzado del Sistema
.DESCRIPTION
    Panel de control con métricas del sistema en tiempo real
#>

$ErrorActionPreference = 'SilentlyContinue'

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           DASHBOARD AVANZADO DEL SISTEMA v2.0" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SystemMetrics {
    $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
    $os = Get-WmiObject Win32_OperatingSystem
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    $diskTotal = [math]::Round($disk.Size / 1GB, 2)
    $diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskUsed = $diskTotal - $diskFree
    $diskPercent = [math]::Round(($diskUsed / $diskTotal) * 100, 1)
    
    return @{
        CPU = @{
            Name = $cpu.Name
            Usage = [math]::Round($cpuUsage, 1)
            Cores = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
        }
        RAM = @{
            Total = $totalRAM
            Used = $usedRAM
            Free = $freeRAM
            Percent = $ramPercent
        }
        Disk = @{
            Total = $diskTotal
            Used = $diskUsed
            Free = $diskFree
            Percent = $diskPercent
        }
        OS = @{
            Name = $os.Caption
            Version = $os.Version
            Architecture = $os.OSArchitecture
        }
    }
}

function Show-Dashboard {
    Show-Header
    
    Write-Host "Recopilando métricas del sistema..." -ForegroundColor Yellow
    $metrics = Get-SystemMetrics
    
    Write-Host "`n==================== RESUMEN DEL SISTEMA ====================`n" -ForegroundColor Cyan
    
    # Sistema Operativo
    Write-Host "SISTEMA OPERATIVO:" -ForegroundColor Green
    Write-Host "  OS: $($metrics.OS.Name)" -ForegroundColor White
    Write-Host "  Version: $($metrics.OS.Version)" -ForegroundColor White
    Write-Host "  Arquitectura: $($metrics.OS.Architecture)" -ForegroundColor White
    Write-Host ""
    
    # CPU
    Write-Host "PROCESADOR:" -ForegroundColor Green
    Write-Host "  Modelo: $($metrics.CPU.Name)" -ForegroundColor White
    Write-Host "  Nucleos: $($metrics.CPU.Cores) fisicos / $($metrics.CPU.LogicalProcessors) logicos" -ForegroundColor White
    $cpuColor = if ($metrics.CPU.Usage -gt 80) { "Red" } elseif ($metrics.CPU.Usage -gt 50) { "Yellow" } else { "Green" }
    Write-Host "  Uso actual: $($metrics.CPU.Usage) porciento" -ForegroundColor $cpuColor
    Write-Host ""
    
    # RAM
    Write-Host "MEMORIA RAM:" -ForegroundColor Green
    Write-Host "  Total: $($metrics.RAM.Total) GB" -ForegroundColor White
    Write-Host "  Usado: $($metrics.RAM.Used) GB" -ForegroundColor White
    Write-Host "  Libre: $($metrics.RAM.Free) GB" -ForegroundColor White
    $ramColor = if ($metrics.RAM.Percent -gt 85) { "Red" } elseif ($metrics.RAM.Percent -gt 70) { "Yellow" } else { "Green" }
    Write-Host "  Uso: $($metrics.RAM.Percent) porciento" -ForegroundColor $ramColor
    Write-Host ""
    
    # Disco
    Write-Host "DISCO C:\" -ForegroundColor Green
    Write-Host "  Capacidad: $($metrics.Disk.Total) GB" -ForegroundColor White
    Write-Host "  Usado: $($metrics.Disk.Used) GB" -ForegroundColor White
    Write-Host "  Libre: $($metrics.Disk.Free) GB" -ForegroundColor White
    $diskColor = if ($metrics.Disk.Percent -gt 90) { "Red" } elseif ($metrics.Disk.Percent -gt 80) { "Yellow" } else { "Green" }
    Write-Host "  Uso: $($metrics.Disk.Percent) porciento" -ForegroundColor $diskColor
    Write-Host ""
    
    Write-Host "============================================================`n" -ForegroundColor Cyan
    
    # Top procesos
    Write-Host "TOP 10 PROCESOS POR USO DE MEMORIA:" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor Gray
    $procs = Get-Process | Where-Object { $_.WorkingSet -gt 0 } | Sort-Object WorkingSet -Descending | Select-Object -First 10
    foreach ($proc in $procs) {
        $mem = [math]::Round($proc.WorkingSet / 1MB, 2)
        $color = if ($mem -gt 500) { "Red" } elseif ($mem -gt 200) { "Yellow" } else { "White" }
        Write-Host "  $($proc.ProcessName.PadRight(30)) $mem MB" -ForegroundColor $color
    }
    Write-Host ("")
    
    Write-Host "Dashboard generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
}

# Ejecutar dashboard
Show-Dashboard
Write-Host "`nPresiona ENTER para salir..." -ForegroundColor Yellow
Read-Host

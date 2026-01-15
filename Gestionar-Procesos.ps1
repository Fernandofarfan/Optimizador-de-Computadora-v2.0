<#
.SYNOPSIS
    Gestor Avanzado de Procesos v4.0
.DESCRIPTION
    Gestiona procesos del sistema y programas de inicio
#>

$ErrorActionPreference = 'Continue'

function Show-Banner {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "           GESTOR DE PROCESOS Y PROGRAMAS DE INICIO" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Get-TopProcesses {
    Write-Host "`nTop 15 procesos por uso de memoria:" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Gray
    Write-Host ("{0,-30} {1,8} {2,15}" -f "Proceso", "PID", "RAM (MB)") -ForegroundColor Yellow
    Write-Host ("-" * 70) -ForegroundColor Gray
    
    $processes = Get-Process | Where-Object { $_.WorkingSet -gt 0 } | 
        Sort-Object WorkingSet -Descending | 
        Select-Object -First 15
    
    foreach ($proc in $processes) {
        $name = $proc.ProcessName
        $pid = $proc.Id
        $mem = [math]::Round($proc.WorkingSet / 1MB, 2)
        
        $color = if ($mem -gt 1000) { "Red" } elseif ($mem -gt 500) { "Yellow" } else { "White" }
        Write-Host ("{0,-30} {1,8} {2,15}" -f $name, $pid, $mem) -ForegroundColor $color
    }
    
    Write-Host ("=" * 70) -ForegroundColor Gray
}

function Get-StartupPrograms {
    Write-Host "`nProgramas de inicio:" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Gray
    
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )
    
    $found = $false
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $items = Get-ItemProperty $path -ErrorAction SilentlyContinue
            if ($items) {
                $location = if ($path -match "HKLM") { "[SISTEMA]" } else { "[USUARIO]" }
                $items.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
                    Write-Host "$location $($_.Name)" -ForegroundColor White
                    $found = $true
                }
            }
        }
    }
    
    if (-not $found) {
        Write-Host "No se encontraron programas de inicio" -ForegroundColor Yellow
    }
    
    Write-Host ("=" * 70) -ForegroundColor Gray
}

function Stop-ProcessByName {
    param([string]$ProcessName)
    
    Write-Host "`nADVERTENCIA: Terminar procesos puede causar perdida de datos" -ForegroundColor Yellow
    $confirm = Read-Host "¿Terminar proceso '$ProcessName'? (S/N)"
    
    if ($confirm -eq 'S' -or $confirm -eq 's') {
        try {
            $procs = Get-Process -Name $ProcessName -ErrorAction Stop
            Stop-Process -Name $ProcessName -Force -ErrorAction Stop
            Write-Host "Proceso terminado: $($procs.Count) instancia(s)" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: No se pudo terminar el proceso" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Operacion cancelada" -ForegroundColor Yellow
    }
}

function Remove-StartupProgram {
    param([string]$ProgramName)
    
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )
    
    $found = $false
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                $items = Get-ItemProperty $path -ErrorAction SilentlyContinue
                if ($items.PSObject.Properties.Name -contains $ProgramName) {
                    Remove-ItemProperty -Path $path -Name $ProgramName -ErrorAction Stop
                    Write-Host "Programa eliminado del inicio: $ProgramName" -ForegroundColor Green
                    $found = $true
                }
            }
            catch {
                Write-Host "Error al eliminar: $_" -ForegroundColor Red
            }
        }
    }
    
    if (-not $found) {
        Write-Host "No se encontro el programa: $ProgramName" -ForegroundColor Yellow
    }
}

function Optimize-Boot {
    Write-Host "`nOptimizando arranque del sistema..." -ForegroundColor Cyan
    
    # Deshabilitar programas comunes del inicio
    $toDisable = @("Spotify", "Discord", "Steam", "Skype", "Teams")
    $disabled = 0
    
    foreach ($prog in $toDisable) {
        $paths = @(
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        )
        
        foreach ($path in $paths) {
            if (Test-Path $path) {
                try {
                    $items = Get-ItemProperty $path -ErrorAction SilentlyContinue
                    if ($items.PSObject.Properties.Name -contains $prog) {
                        Remove-ItemProperty -Path $path -Name $prog -ErrorAction Stop
                        $disabled++
                    }
                }
                catch {
                    # Ignorar errores
                }
            }
        }
    }
    
    Write-Host "Programas deshabilitados del inicio: $disabled" -ForegroundColor Green
    
    # Optimizar servicios
    Write-Host "Optimizando servicios..." -ForegroundColor Yellow
    $services = @("DiagTrack", "dmwappushservice")
    
    foreach ($svc in $services) {
        try {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }
        catch {
            # Ignorar errores
        }
    }
    
    Write-Host "Optimizacion completada" -ForegroundColor Green
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "MENU PRINCIPAL:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Ver procesos mas pesados" -ForegroundColor White
        Write-Host "  [2] Terminar proceso por nombre" -ForegroundColor White
        Write-Host "  [3] Ver programas de inicio" -ForegroundColor White
        Write-Host "  [4] Eliminar programa del inicio" -ForegroundColor White
        Write-Host "  [5] Optimizar arranque del sistema" -ForegroundColor White
        Write-Host "  [0] Salir" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Selecciona una opcion"
        
        switch ($choice) {
            '1' {
                Get-TopProcesses
                Read-Host "`nPresiona ENTER para continuar"
            }
            '2' {
                $procName = Read-Host "`nIngresa el nombre del proceso"
                if ($procName) {
                    Stop-ProcessByName -ProcessName $procName
                }
                Read-Host "`nPresiona ENTER para continuar"
            }
            '3' {
                Get-StartupPrograms
                Read-Host "`nPresiona ENTER para continuar"
            }
            '4' {
                $progName = Read-Host "`nIngresa el nombre exacto del programa"
                if ($progName) {
                    Remove-StartupProgram -ProgramName $progName
                }
                Read-Host "`nPresiona ENTER para continuar"
            }
            '5' {
                Optimize-Boot
                Read-Host "`nPresiona ENTER para continuar"
            }
            '0' {
                Write-Host "`nSaliendo..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "`nOpcion invalida" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Ejecutar menu principal
Show-Menu

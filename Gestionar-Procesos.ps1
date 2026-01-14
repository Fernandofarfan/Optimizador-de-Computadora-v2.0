Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "       GESTOR DE PROCESOS" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "PROCESOS PRINCIPALES EN EJECUCION:" -ForegroundColor Yellow
Write-Host ""

$topProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10

Write-Host "Proceso                              CPU (%)    Memoria (MB)" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Cyan

foreach ($proc in $topProcesses) {
    $cpu = [math]::Round($proc.CPU, 1)
    $mem = [math]::Round($proc.WorkingSet / 1MB, 1)
    $name = $proc.ProcessName.PadRight(35)
    Write-Host "$name $($cpu.ToString().PadLeft(8))   $($mem.ToString().PadLeft(8))" -ForegroundColor Green
}

Write-Host ""
Write-Host "OPCIONES:" -ForegroundColor Yellow
Write-Host "1. Ver todos los procesos (Get-Process)" -ForegroundColor Gray
Write-Host "2. Terminar proceso (admin requerido)" -ForegroundColor Gray
Write-Host "3. Ver detalles de un proceso" -ForegroundColor Gray
Write-Host ""

$opcion = Read-Host "Selecciona (1-3) o ENTER para salir"

switch($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Listado completo de procesos:" -ForegroundColor Cyan
        Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 15 | Format-Table Name, CPU, @{N="MemoriaMB"; E={[math]::Round($_.WorkingSet/1MB,1)}} -AutoSize
    }
    "2" {
        $procName = Read-Host "Nombre del proceso a terminar"
        if ($procName) {
            try {
                Stop-Process -Name $procName -Force -ErrorAction Stop
                Write-Host "✓ Proceso $procName terminado" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Error: No se pudo terminar el proceso" -ForegroundColor Red
            }
        }
    }
    "3" {
        $procName = Read-Host "Nombre del proceso a consultar"
        if ($procName) {
            try {
                $proc = Get-Process -Name $procName -ErrorAction Stop | Select-Object -First 1
                Write-Host ""
                Write-Host "Detalles del proceso:" -ForegroundColor Cyan
                Write-Host "  Nombre: $($proc.ProcessName)" -ForegroundColor White
                Write-Host "  PID: $($proc.Id)" -ForegroundColor White
                Write-Host "  CPU: $([math]::Round($proc.CPU, 2)) segundos" -ForegroundColor White
                Write-Host "  Memoria: $([math]::Round($proc.WorkingSet / 1MB, 2)) MB" -ForegroundColor White
                Write-Host "  Inicio: $($proc.StartTime)" -ForegroundColor White
            } catch {
                Write-Host "⚠ Proceso no encontrado" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

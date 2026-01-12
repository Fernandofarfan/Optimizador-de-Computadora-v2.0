# ============================================
# Crear-TareasProgramadas.ps1
# Programa tareas automáticas de mantenimiento
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PROGRAMADOR DE TAREAS AUTOMÁTICAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando configuración de tareas programadas" -Level "INFO"

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Log "Intento de crear tareas sin permisos de admin" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit 1
}

Write-Host "Este script creará tareas automáticas de mantenimiento:" -ForegroundColor White
Write-Host ""
Write-Host "📅 TAREAS A CREAR:" -ForegroundColor Cyan
Write-Host "  [1] Limpieza Automática Semanal - Domingos 2:00 AM" -ForegroundColor White
Write-Host "  [2] Análisis de Seguridad Mensual - Primer día del mes 3:00 AM" -ForegroundColor White
Write-Host "  [3] Backup de Logs Quincenal - Días 1 y 15 a las 4:00 AM" -ForegroundColor White
Write-Host "  [4] Análisis de Sistema Semanal - Lunes 1:00 AM" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Las tareas se ejecutarán aunque el PC esté en uso" -ForegroundColor Yellow
Write-Host "💡 Puedes modificar/eliminar tareas desde el Programador de Tareas de Windows" -ForegroundColor Gray
Write-Host ""
Write-Host "¿Deseas continuar? (S/N): " -NoNewline
$response = Read-Host

if ($response -ne "S" -and $response -ne "s") {
    Write-Host "Operación cancelada" -ForegroundColor Gray
    Write-Log "Usuario canceló creación de tareas programadas" -Level "INFO"
    exit 0
}

Write-Host ""

$tareasCreadas = 0
$tareasError = 0

# ============================================
# 1. LIMPIEZA AUTOMÁTICA SEMANAL
# ============================================

Write-Host "[1/4] Creando tarea: Limpieza Semanal..." -ForegroundColor Cyan

try {
    $taskName = "PC Optimizer - Limpieza Semanal"
    $taskDescription = "Limpieza automática del sistema cada domingo a las 2:00 AM"
    
    # Eliminar tarea si ya existe
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Acción: Ejecutar script de limpieza
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath\Limpieza-Profunda.ps1`""
    
    # Trigger: Domingos a las 2:00 AM
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2:00AM
    
    # Configuración: Ejecutar con privilegios más altos
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
    
    # Registrar tarea
    Register-ScheduledTask -TaskName $taskName -Description $taskDescription `
        -Action $action -Trigger $trigger -Principal $principal -Settings $settings -ErrorAction Stop | Out-Null
    
    Write-Host "  ✅ Tarea creada: $taskName" -ForegroundColor Green
    Write-Log "Tarea programada creada: $taskName" -Level "SUCCESS"
    $tareasCreadas++
} catch {
    Write-Host "  ❌ Error al crear tarea de limpieza" -ForegroundColor Red
    Write-Log "Error al crear tarea de limpieza: $($_.Exception.Message)" -Level "ERROR"
    $tareasError++
}

Write-Host ""

# ============================================
# 2. ANÁLISIS DE SEGURIDAD MENSUAL
# ============================================

Write-Host "[2/4] Creando tarea: Análisis de Seguridad Mensual..." -ForegroundColor Cyan

try {
    $taskName = "PC Optimizer - Seguridad Mensual"
    $taskDescription = "Análisis de seguridad automático el primer día de cada mes a las 3:00 AM"
    
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath\Analizar-Seguridad.ps1`""
    
    # Trigger: Primer día del mes a las 3:00 AM
    $trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
    $trigger.DaysInterval = 1
    # Modificar para que sea mensual
    $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 3:00AM
    
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $taskName -Description $taskDescription `
        -Action $action -Trigger $trigger -Principal $principal -Settings $settings -ErrorAction Stop | Out-Null
    
    Write-Host "  ✅ Tarea creada: $taskName" -ForegroundColor Green
    Write-Log "Tarea programada creada: $taskName" -Level "SUCCESS"
    $tareasCreadas++
} catch {
    Write-Host "  ❌ Error al crear tarea de seguridad" -ForegroundColor Red
    Write-Log "Error al crear tarea de seguridad: $($_.Exception.Message)" -Level "ERROR"
    $tareasError++
}

Write-Host ""

# ============================================
# 3. BACKUP DE LOGS QUINCENAL
# ============================================

Write-Host "[3/4] Creando tarea: Backup de Logs..." -ForegroundColor Cyan

try {
    $taskName = "PC Optimizer - Backup Logs Quincenal"
    $taskDescription = "Backup de logs los días 1 y 15 de cada mes a las 4:00 AM"
    
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Crear script de backup inline
    $backupScript = @"
`$logsPath = "$scriptPath\logs"
`$backupPath = "$scriptPath\logs\backups"
if (-not (Test-Path `$backupPath)) { New-Item -ItemType Directory -Path `$backupPath -Force }
`$date = Get-Date -Format 'yyyyMMdd'
`$zipFile = "`$backupPath\logs_backup_`$date.zip"
if (Test-Path `$logsPath) {
    Compress-Archive -Path "`$logsPath\*.log" -DestinationPath `$zipFile -Force
}
"@
    
    $backupScriptPath = "$scriptPath\Backup-Logs-Auto.ps1"
    $backupScript | Out-File -FilePath $backupScriptPath -Encoding UTF8 -Force
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$backupScriptPath`""
    
    # Trigger: Días 1 y 15 a las 4:00 AM
    $trigger1 = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 4:00AM
    $trigger2 = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 15 -At 4:00AM
    
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    Register-ScheduledTask -TaskName $taskName -Description $taskDescription `
        -Action $action -Trigger $trigger1,$trigger2 -Principal $principal -Settings $settings -ErrorAction Stop | Out-Null
    
    Write-Host "  ✅ Tarea creada: $taskName" -ForegroundColor Green
    Write-Log "Tarea programada creada: $taskName" -Level "SUCCESS"
    $tareasCreadas++
} catch {
    Write-Host "  ❌ Error al crear tarea de backup" -ForegroundColor Red
    Write-Log "Error al crear tarea de backup: $($_.Exception.Message)" -Level "ERROR"
    $tareasError++
}

Write-Host ""

# ============================================
# 4. ANÁLISIS DE SISTEMA SEMANAL
# ============================================

Write-Host "[4/4] Creando tarea: Análisis de Sistema Semanal..." -ForegroundColor Cyan

try {
    $taskName = "PC Optimizer - Análisis Sistema Semanal"
    $taskDescription = "Análisis completo del sistema cada lunes a la 1:00 AM"
    
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath\Analizar-Sistema.ps1`""
    
    # Trigger: Lunes a la 1:00 AM
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 1:00AM
    
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $taskName -Description $taskDescription `
        -Action $action -Trigger $trigger -Principal $principal -Settings $settings -ErrorAction Stop | Out-Null
    
    Write-Host "  ✅ Tarea creada: $taskName" -ForegroundColor Green
    Write-Log "Tarea programada creada: $taskName" -Level "SUCCESS"
    $tareasCreadas++
} catch {
    Write-Host "  ❌ Error al crear tarea de análisis" -ForegroundColor Red
    Write-Log "Error al crear tarea de análisis: $($_.Exception.Message)" -Level "ERROR"
    $tareasError++
}

Write-Host ""

# ============================================
# RESUMEN
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURACIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Tareas creadas: $tareasCreadas/4" -ForegroundColor Green
if ($tareasError -gt 0) {
    Write-Host "❌ Errores: $tareasError" -ForegroundColor Red
}

Write-Host ""
Write-Host "📅 CRONOGRAMA DE TAREAS:" -ForegroundColor Cyan
Write-Host "  • Lunes 1:00 AM - Análisis de Sistema" -ForegroundColor White
Write-Host "  • Domingos 2:00 AM - Limpieza Profunda" -ForegroundColor White
Write-Host "  • Primer día del mes 3:00 AM - Análisis de Seguridad" -ForegroundColor White
Write-Host "  • Días 1 y 15 a las 4:00 AM - Backup de Logs" -ForegroundColor White

Write-Host ""
Write-Host "💡 GESTIÓN DE TAREAS:" -ForegroundColor Yellow
Write-Host "  • Ver tareas: taskschd.msc (Programador de tareas)" -ForegroundColor White
Write-Host "  • Buscar: 'PC Optimizer'" -ForegroundColor White
Write-Host "  • Modificar horarios: Clic derecho > Propiedades" -ForegroundColor White
Write-Host "  • Deshabilitar: Clic derecho > Deshabilitar" -ForegroundColor White
Write-Host "  • Eliminar: Clic derecho > Eliminar" -ForegroundColor White

Write-Host ""
Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "  • Las tareas se ejecutan en segundo plano" -ForegroundColor White
Write-Host "  • No verás ventanas al ejecutarse" -ForegroundColor White
Write-Host "  • Revisa los logs en la carpeta 'logs' para ver resultados" -ForegroundColor White
Write-Host "  • Si tu PC está apagado, la tarea se ejecutará al encenderlo" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Configuración de tareas programadas completada: $tareasCreadas creadas, $tareasError errores" -Level "SUCCESS"

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

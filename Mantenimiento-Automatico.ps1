#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Programador de Mantenimiento Automático del Sistema
.DESCRIPTION
    Herramienta profesional para automatizar tareas de mantenimiento:
    - Programar limpiezas automáticas (temporales, caché, logs)
    - Automatizar desfragmentación inteligente
    - Programar actualizaciones del sistema
    - Crear respaldos automáticos
    - Verificación de salud del sistema
    - Optimizaciones periódicas
.NOTES
    Versión: 2.8.0
    Requiere: Windows 10/11, PowerShell 5.1+, Privilegios de administrador
#>

# Importar Logger si existe
if (Test-Path "$PSScriptRoot\Logger.ps1") {
    . "$PSScriptRoot\Logger.ps1"
}

function Write-ColoredText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Clear-Host
    Write-ColoredText "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColoredText "║      MANTENIMIENTO AUTOMÁTICO DEL SISTEMA v2.8.0           ║" "Cyan"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Get-ScheduledMaintenanceTasks {
    <#
    .SYNOPSIS
        Obtiene todas las tareas de mantenimiento programadas
    #>
    $taskPath = "\OptimizadorPC\"
    
    try {
        $tasks = Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue
        return $tasks
    }
    catch {
        return @()
    }
}

function Show-ScheduledTasks {
    <#
    .SYNOPSIS
        Muestra todas las tareas programadas con detalles
    #>
    Write-ColoredText "`n📅 Tareas de Mantenimiento Programadas:" "Cyan"
    Write-Host ""
    
    $tasks = Get-ScheduledMaintenanceTasks
    
    if ($tasks.Count -eq 0) {
        Write-ColoredText "⚠ No hay tareas de mantenimiento programadas" "Yellow"
        return
    }
    
    foreach ($task in $tasks) {
        $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
        
        $status = switch ($task.State) {
            "Ready" { "✅ Activa" }
            "Disabled" { "❌ Deshabilitada" }
            "Running" { "🔄 Ejecutando" }
            default { "⚠ $($task.State)" }
        }
        
        $color = switch ($task.State) {
            "Ready" { "Green" }
            "Disabled" { "Red" }
            "Running" { "Cyan" }
            default { "Yellow" }
        }
        
        Write-ColoredText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Gray"
        Write-ColoredText "Tarea: $($task.TaskName)" "White"
        Write-ColoredText "Estado: $status" $color
        Write-Host "Descripción: $($task.Description)"
        
        if ($info.LastRunTime -ne $null -and $info.LastRunTime.Year -gt 1) {
            Write-Host "Última ejecución: $($info.LastRunTime.ToString('dd/MM/yyyy HH:mm:ss'))"
            Write-Host "Resultado: $($info.LastTaskResult)"
        }
        else {
            Write-Host "Última ejecución: Nunca"
        }
        
        if ($info.NextRunTime -ne $null -and $info.NextRunTime.Year -gt 1) {
            Write-Host "Próxima ejecución: $($info.NextRunTime.ToString('dd/MM/yyyy HH:mm:ss'))"
        }
        
        Write-Host ""
    }
    
    Write-ColoredText "Total: $($tasks.Count) tarea(s) programada(s)" "Green"
}

function New-CleanupTask {
    <#
    .SYNOPSIS
        Crea tarea programada para limpieza automática
    #>
    Write-ColoredText "`n🧹 Configurar Limpieza Automática" "Cyan"
    Write-ColoredText "═════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-Host "Selecciona frecuencia:"
    Write-Host "  1. Diaria (a las 3:00 AM)"
    Write-Host "  2. Semanal (domingos a las 3:00 AM)"
    Write-Host "  3. Mensual (primer domingo del mes)"
    Write-Host ""
    
    $freq = Read-Host "Opción"
    
    $trigger = switch ($freq) {
        "1" { New-ScheduledTaskTrigger -Daily -At "03:00AM" }
        "2" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00AM" }
        "3" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Sunday -At "03:00AM" }
        default {
            Write-ColoredText "❌ Opción inválida" "Red"
            return
        }
    }
    
    # Script de limpieza
    $cleanupScript = @"
# Limpiar temporales de Windows
Remove-Item -Path `$env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path `$env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar caché de navegadores
Remove-Item -Path "`$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "`$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "`$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*.default-release\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar Papelera de Reciclaje
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# Ejecutar Liberador de espacio en disco
Start-Process -FilePath cleanmgr.exe -ArgumentList '/sagerun:1' -Wait -NoNewWindow

# Log
Add-Content -Path "`$env:USERPROFILE\OptimizadorPC-Limpieza.log" -Value "[`$(Get-Date)] Limpieza automática ejecutada"
"@
    
    $scriptPath = "$env:USERPROFILE\OptimizadorPC-Limpieza.ps1"
    $cleanupScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
        
        $taskName = "OptimizadorPC_LimpiezaAutomatica"
        $taskPath = "\OptimizadorPC\"
        
        # Eliminar tarea existente
        $existing = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
        }
        
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Limpieza automática de archivos temporales y caché"
        
        Write-ColoredText "`n✅ Tarea de limpieza creada exitosamente" "Green"
        
        $freqText = switch ($freq) {
            "1" { "diariamente a las 3:00 AM" }
            "2" { "semanalmente los domingos a las 3:00 AM" }
            "3" { "mensualmente el primer domingo a las 3:00 AM" }
        }
        
        Write-ColoredText "   Frecuencia: $freqText" "White"
        Write-ColoredText "   Script: $scriptPath" "White"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Tarea de limpieza automática creada: $freqText" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al crear tarea: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al crear tarea de limpieza: $($_.Exception.Message)" "Error"
        }
    }
}

function New-DefragTask {
    <#
    .SYNOPSIS
        Crea tarea programada para desfragmentación inteligente
    #>
    Write-ColoredText "`n💾 Configurar Desfragmentación Automática" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-Host "Selecciona frecuencia:"
    Write-Host "  1. Semanal (sábados a las 2:00 AM)"
    Write-Host "  2. Mensual (primer sábado del mes)"
    Write-Host ""
    
    $freq = Read-Host "Opción"
    
    $trigger = switch ($freq) {
        "1" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At "02:00AM" }
        "2" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Saturday -At "02:00AM" }
        default {
            Write-ColoredText "❌ Opción inválida" "Red"
            return
        }
    }
    
    # Script de desfragmentación inteligente
    $defragScript = @"
# Obtener tipo de disco
`$drive = Get-PhysicalDisk | Where-Object { `$_.DeviceID -eq 0 }
`$mediaType = `$drive.MediaType

if (`$mediaType -eq "HDD") {
    # Desfragmentar HDD
    Optimize-Volume -DriveLetter C -Defrag -Verbose
    Add-Content -Path "`$env:USERPROFILE\OptimizadorPC-Defrag.log" -Value "[`$(Get-Date)] Desfragmentación HDD completada"
}
elseif (`$mediaType -eq "SSD") {
    # Optimizar SSD (TRIM)
    Optimize-Volume -DriveLetter C -ReTrim -Verbose
    Add-Content -Path "`$env:USERPROFILE\OptimizadorPC-Defrag.log" -Value "[`$(Get-Date)] Optimización SSD (TRIM) completada"
}
"@
    
    $scriptPath = "$env:USERPROFILE\OptimizadorPC-Defrag.ps1"
    $defragScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -DontStopIfGoingOnBatteries:$false -StartWhenAvailable -RunOnlyIfIdle -IdleDuration (New-TimeSpan -Minutes 10)
        
        $taskName = "OptimizadorPC_DesfragmentacionAutomatica"
        $taskPath = "\OptimizadorPC\"
        
        # Eliminar tarea existente
        $existing = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
        }
        
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Desfragmentación/optimización automática de discos"
        
        Write-ColoredText "`n✅ Tarea de desfragmentación creada exitosamente" "Green"
        
        $freqText = switch ($freq) {
            "1" { "semanalmente los sábados a las 2:00 AM" }
            "2" { "mensualmente el primer sábado a las 2:00 AM" }
        }
        
        Write-ColoredText "   Frecuencia: $freqText" "White"
        Write-ColoredText "   Se ejecutará solo si el sistema está inactivo" "Yellow"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Tarea de desfragmentación automática creada: $freqText" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al crear tarea: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al crear tarea de desfragmentación: $($_.Exception.Message)" "Error"
        }
    }
}

function New-UpdateTask {
    <#
    .SYNOPSIS
        Crea tarea programada para buscar actualizaciones
    #>
    Write-ColoredText "`n🔄 Configurar Búsqueda de Actualizaciones" "Cyan"
    Write-ColoredText "══════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-Host "Selecciona frecuencia:"
    Write-Host "  1. Semanal (martes a las 10:00 AM)"
    Write-Host "  2. Mensual (segundo martes del mes)"
    Write-Host ""
    
    $freq = Read-Host "Opción"
    
    $trigger = switch ($freq) {
        "1" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Tuesday -At "10:00AM" }
        "2" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 2 -DaysOfWeek Tuesday -At "10:00AM" }
        default {
            Write-ColoredText "❌ Opción inválida" "Red"
            return
        }
    }
    
    # Script de actualización
    $updateScript = @"
# Buscar actualizaciones disponibles
`$updateSession = New-Object -ComObject Microsoft.Update.Session
`$updateSearcher = `$updateSession.CreateUpdateSearcher()

try {
    `$searchResult = `$updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
    `$updateCount = `$searchResult.Updates.Count
    
    Add-Content -Path "`$env:USERPROFILE\OptimizadorPC-Updates.log" -Value "[`$(Get-Date)] Actualizaciones encontradas: `$updateCount"
    
    if (`$updateCount -gt 0) {
        # Crear notificación
        Add-Type -AssemblyName System.Windows.Forms
        `$notification = New-Object System.Windows.Forms.NotifyIcon
        `$notification.Icon = [System.Drawing.SystemIcons]::Information
        `$notification.BalloonTipTitle = "Actualizaciones Disponibles"
        `$notification.BalloonTipText = "Se encontraron `$updateCount actualizaciones para tu sistema"
        `$notification.Visible = `$true
        `$notification.ShowBalloonTip(5000)
    }
}
catch {
    Add-Content -Path "`$env:USERPROFILE\OptimizadorPC-Updates.log" -Value "[`$(Get-Date)] Error: `$(`$_.Exception.Message)"
}
"@
    
    $scriptPath = "$env:USERPROFILE\OptimizadorPC-Updates.ps1"
    $updateScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        
        $taskName = "OptimizadorPC_BuscarActualizaciones"
        $taskPath = "\OptimizadorPC\"
        
        # Eliminar tarea existente
        $existing = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
        }
        
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Búsqueda automática de actualizaciones de Windows"
        
        Write-ColoredText "`n✅ Tarea de actualización creada exitosamente" "Green"
        
        $freqText = switch ($freq) {
            "1" { "semanalmente los martes a las 10:00 AM" }
            "2" { "mensualmente el segundo martes a las 10:00 AM" }
        }
        
        Write-ColoredText "   Frecuencia: $freqText" "White"
        Write-ColoredText "   Recibirás notificaciones de actualizaciones disponibles" "Yellow"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Tarea de búsqueda de actualizaciones creada: $freqText" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al crear tarea: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al crear tarea de actualización: $($_.Exception.Message)" "Error"
        }
    }
}

function New-HealthCheckTask {
    <#
    .SYNOPSIS
        Crea tarea programada para verificación de salud del sistema
    #>
    Write-ColoredText "`n🏥 Configurar Verificación de Salud" "Cyan"
    Write-ColoredText "════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-Host "Selecciona frecuencia:"
    Write-Host "  1. Semanal (viernes a las 6:00 PM)"
    Write-Host "  2. Mensual (último viernes del mes)"
    Write-Host ""
    
    $freq = Read-Host "Opción"
    
    $trigger = switch ($freq) {
        "1" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At "06:00PM" }
        "2" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Friday -At "06:00PM" }
        default {
            Write-ColoredText "❌ Opción inválida" "Red"
            return
        }
    }
    
    # Script de verificación de salud
    $healthScript = @"
`$reportPath = "`$env:USERPROFILE\OptimizadorPC-Salud-`$(Get-Date -Format 'yyyyMMdd').txt"

# Iniciar reporte
"===== REPORTE DE SALUD DEL SISTEMA =====" | Out-File `$reportPath
"Fecha: `$(Get-Date)" | Out-File `$reportPath -Append
"" | Out-File `$reportPath -Append

# Verificar disco
"=== ESTADO DEL DISCO ===" | Out-File `$reportPath -Append
Get-Volume | Format-Table -AutoSize | Out-File `$reportPath -Append

# Verificar errores del sistema
"=== ERRORES RECIENTES ===" | Out-File `$reportPath -Append
Get-EventLog -LogName System -EntryType Error -Newest 10 -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-File `$reportPath -Append

# Verificar servicios críticos
"=== SERVICIOS CRÍTICOS ===" | Out-File `$reportPath -Append
`$criticalServices = @("wuauserv", "BITS", "CryptSvc", "TrustedInstaller")
foreach (`$service in `$criticalServices) {
    Get-Service `$service | Format-List | Out-File `$reportPath -Append
}

# Verificar temperatura (si está disponible)
"=== TEMPERATURA CPU ===" | Out-File `$reportPath -Append
Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | 
    Select-Object @{Name="Temperatura (°C)"; Expression={(`$_.CurrentTemperature / 10) - 273.15}} | 
    Out-File `$reportPath -Append

# Verificar integridad del sistema
"=== VERIFICACIÓN DE ARCHIVOS DEL SISTEMA ===" | Out-File `$reportPath -Append
sfc /verifyonly | Out-File `$reportPath -Append

Add-Content -Path "`$env:USERPROFILE\OptimizadorPC-Salud.log" -Value "[`$(Get-Date)] Verificación de salud completada. Reporte: `$reportPath"

# Crear notificación
Add-Type -AssemblyName System.Windows.Forms
`$notification = New-Object System.Windows.Forms.NotifyIcon
`$notification.Icon = [System.Drawing.SystemIcons]::Information
`$notification.BalloonTipTitle = "Verificación de Salud"
`$notification.BalloonTipText = "Reporte de salud del sistema generado"
`$notification.Visible = `$true
`$notification.ShowBalloonTip(5000)
"@
    
    $scriptPath = "$env:USERPROFILE\OptimizadorPC-Salud.ps1"
    $healthScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        $taskName = "OptimizadorPC_VerificacionSalud"
        $taskPath = "\OptimizadorPC\"
        
        # Eliminar tarea existente
        $existing = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
        }
        
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Verificación automática de salud del sistema"
        
        Write-ColoredText "`n✅ Tarea de verificación de salud creada exitosamente" "Green"
        
        $freqText = switch ($freq) {
            "1" { "semanalmente los viernes a las 6:00 PM" }
            "2" { "mensualmente el último viernes a las 6:00 PM" }
        }
        
        Write-ColoredText "   Frecuencia: $freqText" "White"
        Write-ColoredText "   Los reportes se guardarán en tu carpeta de usuario" "Yellow"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Tarea de verificación de salud creada: $freqText" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al crear tarea: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al crear tarea de salud: $($_.Exception.Message)" "Error"
        }
    }
}

function Remove-MaintenanceTask {
    <#
    .SYNOPSIS
        Elimina una tarea de mantenimiento específica
    #>
    Write-ColoredText "`n🗑️ Eliminar Tarea de Mantenimiento" "Cyan"
    Write-ColoredText "═══════════════════════════════════" "Cyan"
    Write-Host ""
    
    $tasks = Get-ScheduledMaintenanceTasks
    
    if ($tasks.Count -eq 0) {
        Write-ColoredText "⚠ No hay tareas de mantenimiento programadas" "Yellow"
        return
    }
    
    Write-Host "Tareas disponibles:"
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        Write-Host "  $($i + 1). $($tasks[$i].TaskName)"
    }
    Write-Host ""
    
    $selection = Read-Host "Selecciona número de tarea a eliminar (0 para cancelar)"
    
    if ($selection -eq "0") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $tasks.Count) {
        $taskToRemove = $tasks[[int]$selection - 1]
        
        $confirm = Read-Host "¿Eliminar '$($taskToRemove.TaskName)'? (S/N)"
        
        if ($confirm -eq "S") {
            try {
                Unregister-ScheduledTask -TaskName $taskToRemove.TaskName -TaskPath $taskToRemove.TaskPath -Confirm:$false
                
                Write-ColoredText "`n✅ Tarea eliminada exitosamente" "Green"
                
                if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                    Write-Log "Tarea eliminada: $($taskToRemove.TaskName)" "Info"
                }
            }
            catch {
                Write-ColoredText "❌ Error al eliminar tarea: $($_.Exception.Message)" "Red"
                if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                    Write-Log "Error al eliminar tarea: $($_.Exception.Message)" "Error"
                }
            }
        }
        else {
            Write-ColoredText "❌ Operación cancelada" "Yellow"
        }
    }
    else {
        Write-ColoredText "❌ Selección inválida" "Red"
    }
}

function Enable-DisableTask {
    <#
    .SYNOPSIS
        Habilita o deshabilita una tarea de mantenimiento
    #>
    Write-ColoredText "`n🔄 Habilitar/Deshabilitar Tarea" "Cyan"
    Write-ColoredText "═══════════════════════════════════" "Cyan"
    Write-Host ""
    
    $tasks = Get-ScheduledMaintenanceTasks
    
    if ($tasks.Count -eq 0) {
        Write-ColoredText "⚠ No hay tareas de mantenimiento programadas" "Yellow"
        return
    }
    
    Write-Host "Tareas disponibles:"
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        $status = if ($tasks[$i].State -eq "Ready") { "✅ Activa" } else { "❌ Deshabilitada" }
        Write-Host "  $($i + 1). $($tasks[$i].TaskName) - $status"
    }
    Write-Host ""
    
    $selection = Read-Host "Selecciona número de tarea (0 para cancelar)"
    
    if ($selection -eq "0") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $tasks.Count) {
        $task = $tasks[[int]$selection - 1]
        
        try {
            if ($task.State -eq "Ready") {
                Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath | Out-Null
                Write-ColoredText "`n✅ Tarea deshabilitada" "Green"
            }
            else {
                Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath | Out-Null
                Write-ColoredText "`n✅ Tarea habilitada" "Green"
            }
            
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log "Tarea modificada: $($task.TaskName)" "Info"
            }
        }
        catch {
            Write-ColoredText "❌ Error: $($_.Exception.Message)" "Red"
        }
    }
    else {
        Write-ColoredText "❌ Selección inválida" "Red"
    }
}

function Start-ManualMaintenance {
    <#
    .SYNOPSIS
        Ejecuta todas las tareas de mantenimiento manualmente
    #>
    Write-ColoredText "`n🚀 Ejecutar Mantenimiento Completo Ahora" "Cyan"
    Write-ColoredText "═════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-ColoredText "⚠ Esto ejecutará todas las tareas de mantenimiento inmediatamente" "Yellow"
    Write-ColoredText "   • Limpieza de archivos temporales" "White"
    Write-ColoredText "   • Optimización de discos" "White"
    Write-ColoredText "   • Verificación de salud" "White"
    Write-Host ""
    
    $confirm = Read-Host "¿Continuar? (S/N)"
    
    if ($confirm -ne "S") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    Write-ColoredText "`n🔄 Iniciando mantenimiento completo..." "Cyan"
    
    # Limpieza
    Write-ColoredText "`n[1/3] Limpiando archivos temporales..." "Yellow"
    try {
        Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-ColoredText "✅ Limpieza completada" "Green"
    }
    catch {
        Write-ColoredText "⚠ Limpieza parcial" "Yellow"
    }
    
    # Optimización de disco
    Write-ColoredText "`n[2/3] Optimizando disco..." "Yellow"
    try {
        $drive = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 }
        if ($drive.MediaType -eq "SSD") {
            Optimize-Volume -DriveLetter C -ReTrim -ErrorAction Stop
            Write-ColoredText "✅ SSD optimizado (TRIM)" "Green"
        }
        else {
            Optimize-Volume -DriveLetter C -Analyze -ErrorAction Stop
            Write-ColoredText "✅ Disco analizado" "Green"
        }
    }
    catch {
        Write-ColoredText "⚠ Optimización de disco omitida" "Yellow"
    }
    
    # Verificación de salud
    Write-ColoredText "`n[3/3] Verificando salud del sistema..." "Yellow"
    try {
        $errorCount = (Get-EventLog -LogName System -EntryType Error -Newest 10 -ErrorAction SilentlyContinue).Count
        Write-ColoredText "✅ Verificación completada: $errorCount errores recientes" "Green"
    }
    catch {
        Write-ColoredText "⚠ Verificación parcial" "Yellow"
    }
    
    Write-ColoredText "`n✅ Mantenimiento completo finalizado" "Green"
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Mantenimiento manual completo ejecutado" "Info"
    }
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

do {
    Show-Header
    
    Write-Host "  📋 GESTIÓN DE TAREAS"
    Write-Host "  ─────────────────────"
    Write-Host "  1. 📅 Ver tareas programadas"
    Write-Host "  2. ➕ Nueva tarea: Limpieza automática"
    Write-Host "  3. ➕ Nueva tarea: Desfragmentación automática"
    Write-Host "  4. ➕ Nueva tarea: Buscar actualizaciones"
    Write-Host "  5. ➕ Nueva tarea: Verificación de salud"
    Write-Host ""
    Write-Host "  🔧 ADMINISTRACIÓN"
    Write-Host "  ─────────────────────"
    Write-Host "  6. 🔄 Habilitar/Deshabilitar tarea"
    Write-Host "  7. 🗑️ Eliminar tarea"
    Write-Host "  8. 🚀 Ejecutar mantenimiento ahora"
    Write-Host ""
    Write-Host "  0. ↩️  Volver al menú principal"
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción"
    
    switch ($opcion) {
        "1" {
            Show-Header
            Show-ScheduledTasks
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "2" {
            Show-Header
            New-CleanupTask
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "3" {
            Show-Header
            New-DefragTask
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "4" {
            Show-Header
            New-UpdateTask
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "5" {
            Show-Header
            New-HealthCheckTask
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "6" {
            Show-Header
            Enable-DisableTask
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "7" {
            Show-Header
            Remove-MaintenanceTask
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "8" {
            Show-Header
            Start-ManualMaintenance
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "0" {
            Write-ColoredText "`n✅ Volviendo al menú principal..." "Green"
            Start-Sleep -Seconds 1
        }
        default {
            Write-ColoredText "`n❌ Opción inválida" "Red"
            Start-Sleep -Seconds 2
        }
    }
} while ($opcion -ne "0")

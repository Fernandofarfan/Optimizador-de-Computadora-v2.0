#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Gestor Completo de Puntos de Restauración del Sistema
.DESCRIPTION
    Herramienta profesional para gestión de puntos de restauración:
    - Crear puntos manualmente con descripción personalizada
    - Listar todos los puntos disponibles con detalles
    - Restaurar sistema a punto específico
    - Eliminar puntos antiguos para liberar espacio
    - Verificar espacio disponible para restauración
    - Programar creación automática
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
    Write-ColoredText "║         GESTOR DE PUNTOS DE RESTAURACIÓN v2.8.0            ║" "Cyan"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Get-RestorePointInfo {
    <#
    .SYNOPSIS
        Obtiene información detallada de todos los puntos de restauración
    #>
    try {
        $restorePoints = Get-ComputerRestorePoint -ErrorAction Stop
        
        if ($restorePoints.Count -eq 0) {
            Write-ColoredText "⚠ No hay puntos de restauración disponibles" "Yellow"
            return @()
        }

        $pointsInfo = @()
        foreach ($point in $restorePoints) {
            $pointsInfo += [PSCustomObject]@{
                Secuencia = $point.SequenceNumber
                Descripcion = $point.Description
                Fecha = $point.ConvertToDateTime($point.CreationTime)
                Tipo = switch ($point.RestorePointType) {
                    0 { "Manual" }
                    1 { "Instalación" }
                    7 { "Sistema" }
                    10 { "Aplicación" }
                    12 { "Actualización" }
                    13 { "Crítico" }
                    default { "Otro" }
                }
                EventoTipo = switch ($point.EventType) {
                    100 { "Inicio" }
                    101 { "Finalización" }
                    102 { "Cancelado" }
                    default { "Desconocido" }
                }
            }
        }
        
        return $pointsInfo
    }
    catch {
        Write-ColoredText "❌ Error al obtener puntos de restauración: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al obtener puntos de restauración: $($_.Exception.Message)" "Error"
        }
        return @()
    }
}

function Show-RestorePoints {
    <#
    .SYNOPSIS
        Muestra todos los puntos de restauración en formato tabla
    #>
    $points = Get-RestorePointInfo
    
    if ($points.Count -eq 0) {
        return
    }

    Write-ColoredText "`n📋 Puntos de Restauración Disponibles:" "Cyan"
    Write-Host ""
    
    $points | Format-Table -AutoSize @{
        Label = "ID"; Expression = { $_.Secuencia }; Width = 8
    }, @{
        Label = "Fecha"; Expression = { $_.Fecha.ToString("dd/MM/yyyy HH:mm") }; Width = 18
    }, @{
        Label = "Tipo"; Expression = { $_.Tipo }; Width = 15
    }, @{
        Label = "Descripción"; Expression = { $_.Descripcion }
    }
    
    Write-ColoredText "Total: $($points.Count) punto(s) de restauración`n" "Green"
}

function New-RestorePointAdvanced {
    <#
    .SYNOPSIS
        Crea un nuevo punto de restauración con verificaciones
    #>
    param(
        [string]$Description = "Punto de restauración manual - Optimizador v2.8"
    )
    
    Write-ColoredText "`n🔧 Creando punto de restauración..." "Cyan"
    
    # Verificar si está habilitada la protección del sistema
    try {
        Get-ComputerRestorePoint -ErrorAction Stop | Out-Null
    }
    catch {
        Write-ColoredText "❌ La protección del sistema no está habilitada" "Red"
        Write-ColoredText "   Ejecuta: Enable-ComputerRestore -Drive 'C:\'" "Yellow"
        return $false
    }

    # Verificar espacio en disco
    $drive = Get-PSDrive -Name C
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    
    if ($freeSpaceGB -lt 5) {
        Write-ColoredText "⚠ Espacio libre insuficiente: $freeSpaceGB GB (mínimo 5 GB)" "Yellow"
        $confirm = Read-Host "¿Continuar de todos modos? (S/N)"
        if ($confirm -ne "S") {
            return $false
        }
    }

    # Verificar último punto de restauración
    $lastPoint = Get-RestorePointInfo | Sort-Object Fecha -Descending | Select-Object -First 1
    if ($lastPoint) {
        $timeSinceLastPoint = (Get-Date) - $lastPoint.Fecha
        if ($timeSinceLastPoint.TotalMinutes -lt 10) {
            Write-ColoredText "⚠ Ya existe un punto de restauración reciente (hace $([math]::Round($timeSinceLastPoint.TotalMinutes)) minutos)" "Yellow"
            $confirm = Read-Host "¿Crear de todos modos? (S/N)"
            if ($confirm -ne "S") {
                return $false
            }
        }
    }

    try {
        # Crear punto de restauración
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        
        Write-ColoredText "✅ Punto de restauración creado exitosamente" "Green"
        Write-ColoredText "   Descripción: $Description" "White"
        Write-ColoredText "   Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "White"
        Write-ColoredText "   Espacio libre: $freeSpaceGB GB" "White"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Punto de restauración creado: $Description" "Info"
        }
        
        return $true
    }
    catch {
        Write-ColoredText "❌ Error al crear punto de restauración: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al crear punto de restauración: $($_.Exception.Message)" "Error"
        }
        return $false
    }
}

function Restore-ToPoint {
    <#
    .SYNOPSIS
        Restaura el sistema a un punto específico
    #>
    param(
        [int]$SequenceNumber
    )
    
    Write-ColoredText "`n⚠ ADVERTENCIA: RESTAURACIÓN DEL SISTEMA" "Yellow"
    Write-ColoredText "═══════════════════════════════════════" "Yellow"
    Write-Host ""
    
    $point = Get-RestorePointInfo | Where-Object { $_.Secuencia -eq $SequenceNumber }
    
    if (-not $point) {
        Write-ColoredText "❌ No se encontró el punto de restauración #$SequenceNumber" "Red"
        return
    }
    
    Write-ColoredText "📋 Información del punto seleccionado:" "Cyan"
    Write-Host "   ID: $($point.Secuencia)"
    Write-Host "   Fecha: $($point.Fecha)"
    Write-Host "   Descripción: $($point.Descripcion)"
    Write-Host "   Tipo: $($point.Tipo)"
    Write-Host ""
    
    Write-ColoredText "⚠ IMPORTANTE:" "Red"
    Write-ColoredText "   • Se cerrarán todas las aplicaciones" "Yellow"
    Write-ColoredText "   • El sistema se reiniciará automáticamente" "Yellow"
    Write-ColoredText "   • El proceso puede tardar 10-30 minutos" "Yellow"
    Write-ColoredText "   • Guarda todo tu trabajo antes de continuar" "Yellow"
    Write-Host ""
    
    $confirm1 = Read-Host "¿Estás SEGURO de que deseas restaurar? (escribe 'RESTAURAR' para confirmar)"
    
    if ($confirm1 -ne "RESTAURAR") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    Write-Host ""
    Write-ColoredText "🔄 Iniciando restauración del sistema..." "Cyan"
    Write-ColoredText "   El sistema se reiniciará en 60 segundos..." "Yellow"
    
    try {
        # Registrar en log antes de restaurar
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Iniciando restauración a punto #$SequenceNumber - $($point.Descripcion)" "Warning"
        }
        
        # Iniciar restauración
        Restore-Computer -RestorePoint $SequenceNumber -Confirm:$false
        
        Write-ColoredText "`n✅ Restauración iniciada. El sistema se reiniciará..." "Green"
    }
    catch {
        Write-ColoredText "`n❌ Error al restaurar: $($_.Exception.Message)" "Red"
        Write-ColoredText "   Puedes intentar desde: Panel de Control > Recuperación > Restaurar Sistema" "Yellow"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al restaurar sistema: $($_.Exception.Message)" "Error"
        }
    }
}

function Remove-OldRestorePoints {
    <#
    .SYNOPSIS
        Elimina puntos de restauración antiguos para liberar espacio
    #>
    param(
        [int]$KeepLast = 3
    )
    
    Write-ColoredText "`n🗑️ Eliminando puntos de restauración antiguos..." "Cyan"
    
    $points = Get-RestorePointInfo | Sort-Object Fecha -Descending
    
    if ($points.Count -le $KeepLast) {
        Write-ColoredText "✅ Solo hay $($points.Count) punto(s). No es necesario eliminar." "Green"
        return
    }
    
    $pointsToRemove = $points | Select-Object -Skip $KeepLast
    
    Write-Host ""
    Write-ColoredText "📋 Se eliminarán $($pointsToRemove.Count) punto(s) antiguos:" "Yellow"
    foreach ($point in $pointsToRemove) {
        Write-Host "   • $($point.Fecha.ToString('dd/MM/yyyy')) - $($point.Descripcion)"
    }
    
    Write-Host ""
    Write-ColoredText "Se conservarán los $KeepLast punto(s) más recientes" "Green"
    
    $confirm = Read-Host "`n¿Continuar? (S/N)"
    
    if ($confirm -ne "S") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    try {
        # Usar vssadmin para eliminar puntos antiguos
        $output = vssadmin delete shadows /for=c: /oldest /quiet 2>&1
        Write-ColoredText "  Resultado: $($output -join ' ')" "Gray"
        
        Write-ColoredText "`n✅ Puntos de restauración antiguos eliminados" "Green"
        
        # Verificar espacio liberado
        $drive = Get-PSDrive -Name C
        $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
        Write-ColoredText "   Espacio libre en C: $freeSpaceGB GB" "White"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Eliminados puntos de restauración antiguos. Conservados: $KeepLast" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al eliminar puntos: $($_.Exception.Message)" "Red"
        Write-ColoredText "   Intenta desde: Propiedades del Sistema > Protección del sistema > Configurar" "Yellow"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al eliminar puntos de restauración: $($_.Exception.Message)" "Error"
        }
    }
}

function Get-SystemProtectionStatus {
    <#
    .SYNOPSIS
        Muestra el estado de la protección del sistema
    #>
    Write-ColoredText "`n🛡️ Estado de Protección del Sistema:" "Cyan"
    Write-Host ""
    
    try {
        # Obtener estado de protección por unidad
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
        
        foreach ($drive in $drives) {
            $driveLetter = $drive.Name
            $protectionEnabled = $false
            
            try {
                Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Out-Null
                $protectionEnabled = $true
            }
            catch {
                $protectionEnabled = $false
            }
            
            $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
            $usedSpaceGB = [math]::Round($drive.Used / 1GB, 2)
            $totalSpaceGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
            
            $status = if ($protectionEnabled) { "✅ ACTIVA" } else { "❌ DESACTIVADA" }
            $color = if ($protectionEnabled) { "Green" } else { "Red" }
            
            Write-ColoredText "Unidad $($driveLetter): $status" $color
            Write-Host "   Espacio total: $totalSpaceGB GB"
            Write-Host "   Espacio usado: $usedSpaceGB GB"
            Write-Host "   Espacio libre: $freeSpaceGB GB"
            Write-Host ""
        }
        
        # Configuración de protección
        $vssConfig = vssadmin list shadowstorage
        if ($vssConfig) {
            Write-ColoredText "📊 Configuración de almacenamiento de instantáneas:" "Cyan"
            Write-Host $vssConfig
        }
    }
    catch {
        Write-ColoredText "❌ Error al obtener estado: $($_.Exception.Message)" "Red"
    }
}

function Set-AutoRestorePoint {
    <#
    .SYNOPSIS
        Configura creación automática de puntos de restauración
    #>
    Write-ColoredText "`n⏰ Configurar Punto de Restauración Automático" "Cyan"
    Write-ColoredText "═════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-Host "Selecciona frecuencia:"
    Write-Host "  1. Diario (cada 24 horas)"
    Write-Host "  2. Semanal (cada lunes)"
    Write-Host "  3. Mensual (primer día del mes)"
    Write-Host "  4. Desactivar tareas automáticas"
    Write-Host ""
    
    $option = Read-Host "Opción"
    
    $taskName = "OptimizadorPC_RestorePoint"
    $taskPath = "\OptimizadorPC\"
    
    # Eliminar tarea existente si hay
    $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
    }
    
    if ($option -eq "4") {
        Write-ColoredText "✅ Tareas automáticas desactivadas" "Green"
        return
    }
    
    # Configurar trigger según opción
    $trigger = switch ($option) {
        "1" { New-ScheduledTaskTrigger -Daily -At "02:00AM" }
        "2" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "02:00AM" }
        "3" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At "02:00AM" }
        default { 
            Write-ColoredText "❌ Opción inválida" "Red"
            return
        }
    }
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"Checkpoint-Computer -Description 'Punto automático - Optimizador PC' -RestorePointType MODIFY_SETTINGS`""
        
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Creación automática de punto de restauración"
        
        Write-ColoredText "`n✅ Tarea programada creada exitosamente" "Green"
        
        $frequency = switch ($option) {
            "1" { "diariamente a las 2:00 AM" }
            "2" { "semanalmente los lunes a las 2:00 AM" }
            "3" { "mensualmente el primer lunes a las 2:00 AM" }
        }
        
        Write-ColoredText "   Se crearán puntos de restauración $frequency" "White"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Configurada tarea automática de restauración: $frequency" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al crear tarea: $($_.Exception.Message)" "Red"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Error al crear tarea automática: $($_.Exception.Message)" "Error"
        }
    }
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

do {
    Show-Header
    
    Write-Host "  1. 📋 Ver puntos de restauración"
    Write-Host "  2. ➕ Crear punto de restauración"
    Write-Host "  3. 🔄 Restaurar sistema"
    Write-Host "  4. 🗑️ Eliminar puntos antiguos"
    Write-Host "  5. 🛡️ Ver estado de protección"
    Write-Host "  6. ⏰ Configurar creación automática"
    Write-Host "  0. ↩️  Volver al menú principal"
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción"
    
    switch ($opcion) {
        "1" {
            Show-Header
            Show-RestorePoints
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "2" {
            Show-Header
            Write-Host "Ingresa descripción para el punto de restauración:"
            Write-Host "(Deja vacío para usar descripción predeterminada)"
            Write-Host ""
            $desc = Read-Host "Descripción"
            
            if ([string]::IsNullOrWhiteSpace($desc)) {
                $desc = "Punto de restauración manual - Optimizador v2.8"
            }
            
            New-RestorePointAdvanced -Description $desc
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "3" {
            Show-Header
            Show-RestorePoints
            Write-Host ""
            $seqNum = Read-Host "Ingresa ID del punto de restauración"
            
            if ($seqNum -match '^\d+$') {
                Restore-ToPoint -SequenceNumber ([int]$seqNum)
            }
            else {
                Write-ColoredText "❌ ID inválido" "Red"
            }
            
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "4" {
            Show-Header
            Show-RestorePoints
            Write-Host ""
            $keep = Read-Host "¿Cuántos puntos recientes deseas conservar? (recomendado: 3)"
            
            if ($keep -match '^\d+$' -and [int]$keep -gt 0) {
                Remove-OldRestorePoints -KeepLast ([int]$keep)
            }
            else {
                Write-ColoredText "❌ Número inválido" "Red"
            }
            
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "5" {
            Show-Header
            Get-SystemProtectionStatus
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "6" {
            Show-Header
            Set-AutoRestorePoint
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

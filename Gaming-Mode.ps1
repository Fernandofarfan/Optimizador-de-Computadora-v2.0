<#
.SYNOPSIS
    Modo Gaming automático para optimizar recursos durante juegos
.DESCRIPTION
    Detecta juegos activos y optimiza el sistema automáticamente
.NOTES
    Versión: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:GamingModeActive = $false
$Global:OriginalSettings = @{}

# Procesos de juegos y plataformas comunes
$Global:GameProcesses = @(
    # Plataformas
    "steam.exe", "steamwebhelper.exe",
    "EpicGamesLauncher.exe", "EpicWebHelper.exe",
    "GalaxyClient.exe", "GalaxyClientService.exe",
    "RiotClientServices.exe", "LeagueClient.exe",
    "Origin.exe", "OriginWebHelperService.exe",
    "Battle.net.exe", "Agent.exe",
    "upc.exe", "UbisoftGameLauncher.exe",
    
    # Juegos populares
    "dota2.exe", "csgo.exe", "cs2.exe",
    "leagueoflegends.exe", "valorant.exe",
    "FortniteClient-Win64-Shipping.exe",
    "RocketLeague.exe",
    "apexlegends.exe",
    "cod.exe", "ModernWarfare.exe",
    "PUBG.exe", "TslGame.exe",
    "Rainbow6.exe", "r5apex.exe",
    "Overwatch.exe", "GTA5.exe",
    "minecraft.exe", "javaw.exe"
)

function Test-GamingProcess {
    <#
    .SYNOPSIS
        Verifica si hay un juego en ejecución
    #>
    
    $runningGames = Get-Process | Where-Object {
        $processName = $_.Name
        $Global:GameProcesses | Where-Object { $_ -like "$processName*" }
    }
    
    return ($runningGames.Count -gt 0)
}

function Enable-GamingMode {
    <#
    .SYNOPSIS
        Activa el modo gaming
    #>
    
    if ($Global:GamingModeActive) {
        Write-Host "ℹ️  Modo Gaming ya está activo" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║          🎮 ACTIVANDO MODO GAMING                      ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    # 1. Deshabilitar Windows Update
    Write-Host "⏸️  Pausando Windows Update..." -ForegroundColor Cyan
    try {
        $updateService = Get-Service -Name wuauserv
        $Global:OriginalSettings.UpdateService = $updateService.Status
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "   ✅ Windows Update pausado" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  No se pudo pausar Windows Update" -ForegroundColor Yellow
    }
    
    # 2. Deshabilitar notificaciones
    Write-Host "🔕 Deshabilitando notificaciones..." -ForegroundColor Cyan
    try {
        $Global:OriginalSettings.QuietHours = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value 0 -ErrorAction SilentlyContinue
        Write-Host "   ✅ Notificaciones deshabilitadas" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  No se pudieron deshabilitar notificaciones" -ForegroundColor Yellow
    }
    
    # 3. Establecer plan de energía en Alto Rendimiento
    Write-Host "⚡ Configurando plan de energía..." -ForegroundColor Cyan
    try {
        $currentPlan = powercfg /getactivescheme
        $Global:OriginalSettings.PowerPlan = $currentPlan
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance GUID
        Write-Host "   ✅ Plan de Alto Rendimiento activado" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  No se pudo cambiar plan de energía" -ForegroundColor Yellow
    }
    
    # 4. Optimizar prioridad de procesos de juego
    Write-Host "🚀 Optimizando prioridad de procesos..." -ForegroundColor Cyan
    $gameProcesses = Get-Process | Where-Object {
        $processName = $_.Name
        $Global:GameProcesses | Where-Object { $_ -like "$processName*" }
    }
    
    foreach ($process in $gameProcesses) {
        try {
            $process.PriorityClass = "High"
            Write-Host "   ✅ Prioridad alta: $($process.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "   ⚠️  No se pudo cambiar prioridad: $($process.Name)" -ForegroundColor Yellow
        }
    }
    
    # 5. Deshabilitar Game Bar si está activo
    Write-Host "🎮 Configurando Xbox Game Bar..." -ForegroundColor Cyan
    try {
        $Global:OriginalSettings.GameBar = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
        Write-Host "   ✅ Game Bar optimizado" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  No se pudo configurar Game Bar" -ForegroundColor Yellow
    }
    
    # 6. Liberar memoria RAM
    Write-Host "🧹 Liberando memoria RAM..." -ForegroundColor Cyan
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-Host "   ✅ Memoria optimizada" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  No se pudo optimizar memoria" -ForegroundColor Yellow
    }
    
    $Global:GamingModeActive = $true
    
    Write-Host "`n🎮 MODO GAMING ACTIVADO 🎮" -ForegroundColor Magenta
    Write-Host "   Tu sistema está optimizado para gaming" -ForegroundColor White
    Write-Host ""
}

function Disable-GamingMode {
    <#
    .SYNOPSIS
        Desactiva el modo gaming y restaura configuración
    #>
    
    if (-not $Global:GamingModeActive) {
        Write-Host "ℹ️  Modo Gaming no está activo" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DESACTIVANDO MODO GAMING                      ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Restaurar Windows Update
    if ($Global:OriginalSettings.UpdateService) {
        Write-Host "🔄 Restaurando Windows Update..." -ForegroundColor Cyan
        try {
            Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Write-Host "   ✅ Windows Update restaurado" -ForegroundColor Green
        }
        catch {
            Write-Host "   ⚠️  No se pudo restaurar Windows Update" -ForegroundColor Yellow
        }
    }
    
    # Restaurar notificaciones
    if ($Global:OriginalSettings.QuietHours) {
        Write-Host "🔔 Restaurando notificaciones..." -ForegroundColor Cyan
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value 1 -ErrorAction SilentlyContinue
            Write-Host "   ✅ Notificaciones restauradas" -ForegroundColor Green
        }
        catch {
            Write-Host "   ⚠️  No se pudieron restaurar notificaciones" -ForegroundColor Yellow
        }
    }
    
    # Restaurar plan de energía
    Write-Host "⚡ Restaurando plan de energía..." -ForegroundColor Cyan
    try {
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e  # Balanced GUID
        Write-Host "   ✅ Plan de energía restaurado" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  No se pudo restaurar plan de energía" -ForegroundColor Yellow
    }
    
    $Global:GamingModeActive = $false
    $Global:OriginalSettings = @{}
    
    Write-Host "`n✅ Configuración normal restaurada" -ForegroundColor Green
    Write-Host ""
}

function Start-GamingMonitor {
    <#
    .SYNOPSIS
        Inicia el monitoreo automático de juegos
    #>
    param(
        [int]$CheckIntervalSeconds = 10
    )
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          MONITOR DE GAMING AUTOMÁTICO                  ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔍 Monitoreando juegos cada $CheckIntervalSeconds segundos..." -ForegroundColor Cyan
    Write-Host "   Presiona Ctrl+C para detener" -ForegroundColor Gray
    Write-Host ""
    
    try {
        while ($true) {
            $isGaming = Test-GamingProcess
            
            if ($isGaming -and -not $Global:GamingModeActive) {
                $runningGames = Get-Process | Where-Object {
                    $processName = $_.Name
                    $Global:GameProcesses | Where-Object { $_ -like "$processName*" }
                } | Select-Object -First 3
                
                Write-Host "🎮 Juego detectado: $($runningGames.Name -join ', ')" -ForegroundColor Green
                Enable-GamingMode
            }
            elseif (-not $isGaming -and $Global:GamingModeActive) {
                Write-Host "ℹ️  No hay juegos en ejecución" -ForegroundColor Yellow
                Disable-GamingMode
            }
            
            Start-Sleep -Seconds $CheckIntervalSeconds
        }
    }
    catch {
        Write-Host "`n⏹️  Monitor detenido" -ForegroundColor Yellow
        if ($Global:GamingModeActive) {
            Disable-GamingMode
        }
    }
}

function Show-GamingStatus {
    <#
    .SYNOPSIS
        Muestra el estado actual del modo gaming
    #>
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          ESTADO DEL MODO GAMING                        ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Global:GamingModeActive) {
        Write-Host "  Estado:         🎮 ACTIVO" -ForegroundColor Green
    }
    else {
        Write-Host "  Estado:         ⭕ INACTIVO" -ForegroundColor Gray
    }
    
    # Detectar juegos activos
    $runningGames = Get-Process | Where-Object {
        $processName = $_.Name
        $Global:GameProcesses | Where-Object { $_ -like "$processName*" }
    }
    
    Write-Host "  Juegos activos: $($runningGames.Count)" -ForegroundColor White
    
    if ($runningGames.Count -gt 0) {
        Write-Host "`n  Procesos detectados:" -ForegroundColor Cyan
        foreach ($game in $runningGames | Select-Object -First 5) {
            $cpuUsage = $game.CPU
            $memoryMB = [math]::Round($game.WorkingSet64 / 1MB, 2)
            Write-Host "    • $($game.Name) - CPU: $cpuUsage% | RAM: $memoryMB MB" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

function Add-GameProcess {
    <#
    .SYNOPSIS
        Agrega un nuevo proceso a la lista de juegos
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    
    if ($ProcessName -notin $Global:GameProcesses) {
        $Global:GameProcesses += $ProcessName
        Write-Host "✅ Proceso agregado: $ProcessName" -ForegroundColor Green
    }
    else {
        Write-Host "ℹ️  El proceso ya está en la lista" -ForegroundColor Yellow
    }
}

# Menú principal
function Show-GamingMenu {
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║          🎮 MODO GAMING AUTOMÁTICO                     ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  1. Activar Modo Gaming manualmente" -ForegroundColor White
    Write-Host "  2. Desactivar Modo Gaming" -ForegroundColor White
    Write-Host "  3. Iniciar monitor automático" -ForegroundColor White
    Write-Host "  4. Ver estado actual" -ForegroundColor White
    Write-Host "  5. Agregar proceso personalizado" -ForegroundColor White
    Write-Host "  0. Volver" -ForegroundColor Gray
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción"
    
    switch ($option) {
        "1" {
            Enable-GamingMode
            Read-Host "`nPresiona Enter para continuar"
            Show-GamingMenu
        }
        "2" {
            Disable-GamingMode
            Read-Host "`nPresiona Enter para continuar"
            Show-GamingMenu
        }
        "3" {
            Start-GamingMonitor
            Show-GamingMenu
        }
        "4" {
            Show-GamingStatus
            Read-Host "`nPresiona Enter para continuar"
            Show-GamingMenu
        }
        "5" {
            $processName = Read-Host "Nombre del proceso (ej: juego.exe)"
            Add-GameProcess -ProcessName $processName
            Read-Host "`nPresiona Enter para continuar"
            Show-GamingMenu
        }
        "0" {
            return
        }
        default {
            Write-Host "❌ Opción inválida" -ForegroundColor Red
            Start-Sleep -Seconds 1
            Show-GamingMenu
        }
    }
}

# Si se ejecuta directamente, mostrar menú
if ($MyInvocation.InvocationName -ne '.') {
    Show-GamingMenu
}

Export-ModuleMember -Function Enable-GamingMode, Disable-GamingMode, Start-GamingMonitor, `
                              Show-GamingStatus, Test-GamingProcess, Add-GameProcess

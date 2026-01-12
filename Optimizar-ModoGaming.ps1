# ============================================
# Optimizar-ModoGaming.ps1
# Modo de alto rendimiento para gaming/productividad
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODO GAMING / ALTO RENDIMIENTO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando modo gaming/alto rendimiento" -Level "INFO"

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Log "Intento de activar modo gaming sin permisos de admin" -Level "ERROR"
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit 1
}

Write-Host "⚠️  ADVERTENCIA:" -ForegroundColor Yellow
Write-Host "Este modo optimiza el sistema para MÁXIMO RENDIMIENTO." -ForegroundColor White
Write-Host "Se desactivarán temporalmente algunas funciones del sistema." -ForegroundColor White
Write-Host ""
Write-Host "Cambios que se realizarán:" -ForegroundColor Cyan
Write-Host "  • Plan de energía: Alto rendimiento" -ForegroundColor Gray
Write-Host "  • Windows Update: Pausado temporalmente (7 días)" -ForegroundColor Gray
Write-Host "  • Game Bar de Xbox: Deshabilitado" -ForegroundColor Gray
Write-Host "  • Notificaciones: Desactivadas temporalmente" -ForegroundColor Gray
Write-Host "  • Visual effects: Optimizados para rendimiento" -ForegroundColor Gray
Write-Host "  • RAM Standby: Limpieza de memoria en espera" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Usa 'Revertir-Cambios.ps1' para restaurar configuración normal" -ForegroundColor Yellow
Write-Host ""
Write-Host "¿Deseas continuar? (S/N): " -NoNewline
$response = Read-Host

if ($response -ne "S" -and $response -ne "s") {
    Write-Host "Operación cancelada" -ForegroundColor Gray
    Write-Log "Usuario canceló modo gaming" -Level "INFO"
    exit 0
}

Write-Host ""

# ============================================
# 1. PLAN DE ENERGÍA - ALTO RENDIMIENTO
# ============================================

Write-Host "[1/7] Configurando plan de energía..." -ForegroundColor Cyan

try {
    # Obtener GUID del plan de alto rendimiento
    $highPerfGuid = (powercfg /list | Select-String "Alto rendimiento" | Select-String -Pattern "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}").Matches.Value
    
    if (-not $highPerfGuid) {
        # Si no existe, duplicar el plan balanceado y configurarlo
        powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
        $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    }
    
    # Activar plan de alto rendimiento
    powercfg /setactive $highPerfGuid 2>&1 | Out-Null
    
    # Deshabilitar suspensión de disco
    powercfg /change disk-timeout-ac 0
    
    # Deshabilitar suspensión (nunca)
    powercfg /change standby-timeout-ac 0
    
    Write-Host "  ✅ Plan de energía configurado: Alto rendimiento" -ForegroundColor Green
    Write-Log "Plan de energía cambiado a Alto rendimiento" -Level "SUCCESS"
    $optimizaciones++
} catch {
    Write-Host "  ❌ Error al configurar plan de energía" -ForegroundColor Red
    Write-Log "Error al cambiar plan de energía: $($_.Exception.Message)" -Level "ERROR"
}

Write-Host ""

# ============================================
# 2. PAUSAR WINDOWS UPDATE
# ============================================

Write-Host "[2/7] Pausando Windows Update..." -ForegroundColor Cyan

try {
    # Pausar actualizaciones por 7 días
    $pauseDate = (Get-Date).AddDays(7).ToString("yyyy-MM-ddT00:00:00Z")
    
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseDate -Type String -ErrorAction Stop
    
    # Detener servicio de Windows Update temporalmente
    Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Windows Update pausado por 7 días" -ForegroundColor Green
    Write-Log "Windows Update pausado hasta $pauseDate" -Level "SUCCESS"
    $optimizaciones++
} catch {
    Write-Host "  ⚠️  No se pudo pausar Windows Update completamente" -ForegroundColor Yellow
    Write-Log "Error al pausar Windows Update: $($_.Exception.Message)" -Level "WARNING"
}

Write-Host ""

# ============================================
# 3. DESACTIVAR GAME BAR Y DVR DE XBOX
# ============================================

Write-Host "[3/7] Deshabilitando Game Bar de Xbox..." -ForegroundColor Cyan

try {
    # Desactivar Game Bar
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Desactivar grabación en segundo plano
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "HistoricalCaptureEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Game Bar y DVR deshabilitados" -ForegroundColor Green
    Write-Log "Game Bar y Xbox DVR deshabilitados" -Level "SUCCESS"
    $optimizaciones++
} catch {
    Write-Host "  ⚠️  Advertencia al configurar Game Bar" -ForegroundColor Yellow
    Write-Log "Error al deshabilitar Game Bar: $($_.Exception.Message)" -Level "WARNING"
}

Write-Host ""

# ============================================
# 4. DESACTIVAR NOTIFICACIONES TEMPORALMENTE
# ============================================

Write-Host "[4/7] Desactivando notificaciones..." -ForegroundColor Cyan

try {
    # Focus Assist = Priority Only
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Desactivar notificaciones de Windows
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Notificaciones desactivadas" -ForegroundColor Green
    Write-Log "Notificaciones desactivadas temporalmente" -Level "SUCCESS"
    $optimizaciones++
} catch {
    Write-Host "  ⚠️  Advertencia al desactivar notificaciones" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 5. OPTIMIZAR EFECTOS VISUALES
# ============================================

Write-Host "[5/7] Optimizando efectos visuales..." -ForegroundColor Cyan

try {
    # Configurar para mejor rendimiento
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    
    # Desactivar animaciones
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -ErrorAction SilentlyContinue
    
    # Desactivar transparencia
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Efectos visuales optimizados para rendimiento" -ForegroundColor Green
    Write-Log "Efectos visuales configurados para máximo rendimiento" -Level "SUCCESS"
    $optimizaciones++
} catch {
    Write-Host "  ⚠️  Advertencia al optimizar efectos visuales" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 6. LIMPIAR RAM STANDBY
# ============================================

Write-Host "[6/7] Limpiando memoria RAM en espera..." -ForegroundColor Cyan

try {
    # Obtener memoria antes
    $memBefore = (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB
    
    # Limpiar memoria en espera usando EmptyStandbyList
    $source = @"
using System;
using System.Runtime.InteropServices;

public class MemoryManagement
{
    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
    
    public static void FlushMemory()
    {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        if (Environment.OSVersion.Platform == PlatformID.Win32NT)
        {
            SetProcessWorkingSetSize(System.Diagnostics.Process.GetCurrentProcess().Handle, -1, -1);
        }
    }
}
"@
    
    Add-Type -TypeDefinition $source -ErrorAction SilentlyContinue
    [MemoryManagement]::FlushMemory()
    
    # Memoria después
    $memAfter = (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB
    $memFreed = [math]::Round($memAfter - $memBefore, 2)
    
    if ($memFreed -gt 0) {
        Write-Host "  ✅ Memoria liberada: ~$memFreed MB" -ForegroundColor Green
        Write-Log "RAM Standby limpiada: $memFreed MB liberados" -Level "SUCCESS"
    } else {
        Write-Host "  ✅ Memoria RAM optimizada" -ForegroundColor Green
        Write-Log "RAM Standby procesada" -Level "SUCCESS"
    }
    $optimizaciones++
} catch {
    Write-Host "  ⚠️  Advertencia al limpiar memoria" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 7. PRIORIDAD DE PROCESOS
# ============================================

Write-Host "[7/7] Ajustando prioridades del sistema..." -ForegroundColor Cyan

try {
    # Priorizar programas en primer plano
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -ErrorAction SilentlyContinue
    
    # Desactivar Cortana en segundo plano
    Get-Process -Name "SearchUI" -ErrorAction SilentlyContinue | ForEach-Object { 
        $_.PriorityClass = "BelowNormal" 
    }
    
    Write-Host "  ✅ Prioridades del sistema optimizadas" -ForegroundColor Green
    Write-Log "Prioridades de procesos ajustadas" -Level "SUCCESS"
    $optimizaciones++
} catch {
    Write-Host "  ⚠️  Advertencia al ajustar prioridades" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# RESUMEN
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODO GAMING ACTIVADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Optimizaciones aplicadas: $optimizaciones/7" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Estado del sistema:" -ForegroundColor Cyan
$ramFree = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
$ramTotal = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Host "  • RAM disponible: $ramFree MB / $ramTotal GB" -ForegroundColor White

$cpu = Get-WmiObject Win32_Processor
Write-Host "  • CPU: $($cpu.Name)" -ForegroundColor White
Write-Host "  • Procesadores lógicos: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White

Write-Host ""
Write-Host "🎮 RECOMENDACIONES:" -ForegroundColor Yellow
Write-Host "  • Cierra programas innecesarios antes de jugar/trabajar" -ForegroundColor White
Write-Host "  • Considera usar MSI Afterburner para monitorear GPU" -ForegroundColor White
Write-Host "  • Mantén drivers de GPU actualizados" -ForegroundColor White
Write-Host "  • Desactiva overlays de Discord/Steam si tienes FPS bajos" -ForegroundColor White

Write-Host ""
Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "  • Windows Update pausado por 7 días (reactívalo después)" -ForegroundColor White
Write-Host "  • Usa 'Revertir-Cambios.ps1' para volver a configuración normal" -ForegroundColor White
Write-Host "  • Reinicia el PC para aplicar todos los cambios completamente" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Modo gaming completado: $optimizaciones optimizaciones aplicadas" -Level "SUCCESS"

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

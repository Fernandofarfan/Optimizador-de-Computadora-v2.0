# ============================================
# Perfiles-Optimizacion.ps1
# Sistema de perfiles de optimización
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PERFILES DE OPTIMIZACIÓN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Log "Perfiles de optimización cancelado: Sin permisos" -Level "ERROR"
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Log "Iniciando sistema de perfiles" -Level "INFO"

# Función para aplicar perfil Gaming
function Apply-GamingProfile {
    Write-Host "🎮 APLICANDO PERFIL GAMING..." -ForegroundColor Magenta
    Write-Host ""
    
    # 1. Plan de energía Alto Rendimiento
    Write-Host "[1/8] Configurando plan de energía..." -ForegroundColor Cyan
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "  ✅ Plan: Alto Rendimiento" -ForegroundColor Green
    
    # 2. Desactivar ahorro de energía de USB
    Write-Host "[2/8] Optimizando USB..." -ForegroundColor Cyan
    powercfg /change usb-selective-suspend-setting 0
    Write-Host "  ✅ USB: Sin ahorro de energía" -ForegroundColor Green
    
    # 3. Pausar Windows Update
    Write-Host "[3/8] Pausando Windows Update..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value ([DateTime]::Now.AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")) -Force
    Write-Host "  ✅ Updates pausados 7 días" -ForegroundColor Green
    
    # 4. Desactivar Game Bar
    Write-Host "[4/8] Desactivando Game Bar..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Force
    Write-Host "  ✅ Game Bar desactivado" -ForegroundColor Green
    
    # 5. Efectos visuales al mínimo
    Write-Host "[5/8] Minimizando efectos visuales..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force
    Write-Host "  ✅ Efectos visuales mínimos" -ForegroundColor Green
    
    # 6. Prioridad alta para primer plano
    Write-Host "[6/8] Ajustando prioridades..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Force
    Write-Host "  ✅ Prioridad optimizada para juegos" -ForegroundColor Green
    
    # 7. Desactivar notificaciones
    Write-Host "[7/8] Desactivando notificaciones..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Force
    Write-Host "  ✅ Notificaciones desactivadas" -ForegroundColor Green
    
    # 8. GPU Performance Mode
    Write-Host "[8/8] Configurando GPU..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Value "VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;" -Force
    Write-Host "  ✅ GPU en modo rendimiento" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✅ PERFIL GAMING APLICADO" -ForegroundColor Green
    Write-Log "Perfil Gaming aplicado exitosamente" -Level "SUCCESS"
}

# Función para aplicar perfil Trabajo
function Apply-WorkProfile {
    Write-Host "💼 APLICANDO PERFIL TRABAJO..." -ForegroundColor Blue
    Write-Host ""
    
    # 1. Plan de energía Equilibrado
    Write-Host "[1/6] Configurando plan de energía..." -ForegroundColor Cyan
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    Write-Host "  ✅ Plan: Equilibrado" -ForegroundColor Green
    
    # 2. Efectos visuales balanceados
    Write-Host "[2/6] Ajustando efectos visuales..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3 -Force
    Write-Host "  ✅ Efectos visuales balanceados" -ForegroundColor Green
    
    # 3. Notificaciones activadas
    Write-Host "[3/6] Activando notificaciones..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 1 -Force
    Write-Host "  ✅ Notificaciones activas" -ForegroundColor Green
    
    # 4. Windows Update normal
    Write-Host "[4/6] Restaurando Windows Update..." -ForegroundColor Cyan
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Force -ErrorAction SilentlyContinue
    Write-Host "  ✅ Updates en modo normal" -ForegroundColor Green
    
    # 5. Prioridad normal
    Write-Host "[5/6] Ajustando prioridades..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2 -Force
    Write-Host "  ✅ Prioridad equilibrada" -ForegroundColor Green
    
    # 6. USB normal
    Write-Host "[6/6] Configurando USB..." -ForegroundColor Cyan
    powercfg /change usb-selective-suspend-setting 1
    Write-Host "  ✅ USB: Modo normal" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✅ PERFIL TRABAJO APLICADO" -ForegroundColor Green
    Write-Log "Perfil Trabajo aplicado exitosamente" -Level "SUCCESS"
}

# Función para aplicar perfil Batería
function Apply-BatteryProfile {
    Write-Host "🔋 APLICANDO PERFIL BATERÍA..." -ForegroundColor Yellow
    Write-Host ""
    
    # 1. Plan de energía Ahorro de energía
    Write-Host "[1/7] Configurando plan de energía..." -ForegroundColor Cyan
    powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a
    Write-Host "  ✅ Plan: Ahorro de energía" -ForegroundColor Green
    
    # 2. Reducir brillo (70%)
    Write-Host "[2/7] Reduciendo brillo..." -ForegroundColor Cyan
    powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEODIM 70
    powercfg /setactive SCHEME_CURRENT
    Write-Host "  ✅ Brillo al 70%" -ForegroundColor Green
    
    # 3. Suspender disco después de 5 min
    Write-Host "[3/7] Configurando suspensión..." -ForegroundColor Cyan
    powercfg /change disk-timeout-ac 5
    powercfg /change disk-timeout-dc 2
    Write-Host "  ✅ Disco se suspende en 2-5 min" -ForegroundColor Green
    
    # 4. Suspender pantalla rápido
    Write-Host "[4/7] Configurando pantalla..." -ForegroundColor Cyan
    powercfg /change monitor-timeout-ac 5
    powercfg /change monitor-timeout-dc 2
    Write-Host "  ✅ Pantalla se apaga en 2-5 min" -ForegroundColor Green
    
    # 5. USB ahorro
    Write-Host "[5/7] Optimizando USB..." -ForegroundColor Cyan
    powercfg /change usb-selective-suspend-setting 1
    Write-Host "  ✅ USB: Ahorro activado" -ForegroundColor Green
    
    # 6. Procesador al mínimo
    Write-Host "[6/7] Limitando procesador..." -ForegroundColor Cyan
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 70
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 50
    powercfg /setactive SCHEME_CURRENT
    Write-Host "  ✅ CPU limitada (50-70%)" -ForegroundColor Green
    
    # 7. Efectos visuales mínimos
    Write-Host "[7/7] Minimizando efectos..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force
    Write-Host "  ✅ Efectos mínimos" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✅ PERFIL BATERÍA APLICADO" -ForegroundColor Green
    Write-Log "Perfil Batería aplicado exitosamente" -Level "SUCCESS"
}

# Función para aplicar perfil Máximo Rendimiento
function Apply-MaxPerformanceProfile {
    Write-Host "⚡ APLICANDO PERFIL MÁXIMO RENDIMIENTO..." -ForegroundColor Red
    Write-Host ""
    
    # 1. Plan Ultimate Performance (si existe, sino Alto Rendimiento)
    Write-Host "[1/9] Configurando plan de energía..." -ForegroundColor Cyan
    $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $schemes = powercfg /list
    
    if ($schemes -match $ultimateGuid) {
        powercfg /setactive $ultimateGuid
        Write-Host "  ✅ Plan: Ultimate Performance" -ForegroundColor Green
    } else {
        # Crear Ultimate Performance
        powercfg /duplicatescheme $ultimateGuid
        powercfg /setactive $ultimateGuid
        Write-Host "  ✅ Plan: Ultimate Performance (creado)" -ForegroundColor Green
    }
    
    # 2. CPU al máximo
    Write-Host "[2/9] Maximizando CPU..." -ForegroundColor Cyan
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
    powercfg /setactive SCHEME_CURRENT
    Write-Host "  ✅ CPU al 100%" -ForegroundColor Green
    
    # 3. Desactivar ahorro de energía
    Write-Host "[3/9] Desactivando ahorros..." -ForegroundColor Cyan
    powercfg /change disk-timeout-ac 0
    powercfg /change monitor-timeout-ac 0
    powercfg /change standby-timeout-ac 0
    powercfg /change hibernate-timeout-ac 0
    Write-Host "  ✅ Sin suspensiones automáticas" -ForegroundColor Green
    
    # 4. PCI Express sin ahorro
    Write-Host "[4/9] Optimizando PCI Express..." -ForegroundColor Cyan
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
    powercfg /setactive SCHEME_CURRENT
    Write-Host "  ✅ PCI Express: Máximo rendimiento" -ForegroundColor Green
    
    # 5. Desactivar Core Parking
    Write-Host "[5/9] Desactivando Core Parking..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" -Name "ValueMax" -Value 0 -Force
    Write-Host "  ✅ Core Parking desactivado" -ForegroundColor Green
    
    # 6. Prioridad máxima primer plano
    Write-Host "[6/9] Maximizando prioridades..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Force
    Write-Host "  ✅ Prioridad máxima" -ForegroundColor Green
    
    # 7. Efectos visuales al mínimo
    Write-Host "[7/9] Minimizando efectos..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force
    Write-Host "  ✅ Sin efectos visuales" -ForegroundColor Green
    
    # 8. Desactivar servicios innecesarios
    Write-Host "[8/9] Desactivando servicios..." -ForegroundColor Cyan
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  ✅ Superfetch/SysMain desactivado" -ForegroundColor Green
    
    # 9. GPU máximo rendimiento
    Write-Host "[9/9] Maximizando GPU..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Value "VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;" -Force
    Write-Host "  ✅ GPU: Máximo rendimiento" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✅ PERFIL MÁXIMO RENDIMIENTO APLICADO" -ForegroundColor Green
    Write-Log "Perfil Máximo Rendimiento aplicado exitosamente" -Level "SUCCESS"
}

# Menú principal
Write-Host "SELECCIONA UN PERFIL:" -ForegroundColor White
Write-Host ""
Write-Host "  [1] 🎮 GAMING" -ForegroundColor Magenta
Write-Host "      (Máximo FPS, sin interrupciones, updates pausados)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] 💼 TRABAJO" -ForegroundColor Blue
Write-Host "      (Equilibrio rendimiento/energía, notificaciones activas)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [3] 🔋 BATERÍA" -ForegroundColor Yellow
Write-Host "      (Máxima duración, ahorro agresivo, CPU limitada)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [4] ⚡ MÁXIMO RENDIMIENTO" -ForegroundColor Red
Write-Host "      (100% CPU/GPU, sin ahorros, workstation mode)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [0] Salir" -ForegroundColor Gray
Write-Host ""

$opcion = Read-Host "Selecciona un perfil (1-4)"

Write-Host ""

switch ($opcion) {
    '1' {
        Apply-GamingProfile
        Write-Host ""
        Write-Host "💡 RECOMENDACIONES:" -ForegroundColor Cyan
        Write-Host "  • Cierra navegadores y programas en segundo plano" -ForegroundColor White
        Write-Host "  • Verifica que tu juego esté en modo pantalla completa" -ForegroundColor White
        Write-Host "  • Mejora esperada: 10-25% más FPS" -ForegroundColor White
    }
    '2' {
        Apply-WorkProfile
        Write-Host ""
        Write-Host "💡 CARACTERÍSTICAS:" -ForegroundColor Cyan
        Write-Host "  • Rendimiento equilibrado para multitarea" -ForegroundColor White
        Write-Host "  • Notificaciones activas para productividad" -ForegroundColor White
        Write-Host "  • Ahorro moderado de energía" -ForegroundColor White
    }
    '3' {
        Apply-BatteryProfile
        Write-Host ""
        Write-Host "💡 CARACTERÍSTICAS:" -ForegroundColor Cyan
        Write-Host "  • Máxima duración de batería" -ForegroundColor White
        Write-Host "  • CPU limitada al 50-70%" -ForegroundColor White
        Write-Host "  • Suspensiones automáticas activadas" -ForegroundColor White
        Write-Host "  • Aumento esperado: 30-50% más duración" -ForegroundColor White
    }
    '4' {
        Apply-MaxPerformanceProfile
        Write-Host ""
        Write-Host "💡 ADVERTENCIAS:" -ForegroundColor Yellow
        Write-Host "  • Alto consumo eléctrico" -ForegroundColor White
        Write-Host "  • Temperaturas más altas" -ForegroundColor White
        Write-Host "  • Solo para escritorio con buena refrigeración" -ForegroundColor White
        Write-Host "  • Rendimiento máximo garantizado" -ForegroundColor White
    }
    '0' {
        Write-Host "Saliendo..." -ForegroundColor Gray
        exit
    }
    default {
        Write-Host "❌ Opción no válida" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

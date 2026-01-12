# ============================================
# Analizar-Seguridad.ps1
# Análisis de seguridad del sistema Windows
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

# Importar logger
. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ANÁLISIS DE SEGURIDAD DEL SISTEMA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando análisis de seguridad del sistema" -Level "INFO"

$reportPath = "$scriptPath\Reporte-Seguridad-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$report = @()
$report += "=================================================="
$report += "REPORTE DE SEGURIDAD - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "=================================================="
$report += ""

$criticalIssues = 0
$warnings = 0
$goodItems = 0

# ============================================
# 1. WINDOWS DEFENDER
# ============================================

Write-Host "[1/7] Analizando Windows Defender..." -ForegroundColor Cyan

$report += "1. WINDOWS DEFENDER"
$report += "-" * 50

try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
    
    # Protección en tiempo real
    if ($defenderStatus.RealTimeProtectionEnabled) {
        Write-Host "  ✅ Protección en tiempo real: ACTIVA" -ForegroundColor Green
        $report += "✅ Protección en tiempo real: ACTIVA"
        $goodItems++
    } else {
        Write-Host "  ❌ Protección en tiempo real: DESACTIVADA" -ForegroundColor Red
        $report += "❌ Protección en tiempo real: DESACTIVADA"
        $criticalIssues++
    }
    
    # Protección en la nube
    if ($defenderStatus.CloudProtectionEnabled) {
        Write-Host "  ✅ Protección en la nube: ACTIVA" -ForegroundColor Green
        $report += "✅ Protección en la nube: ACTIVA"
        $goodItems++
    } else {
        Write-Host "  ⚠️  Protección en la nube: DESACTIVADA" -ForegroundColor Yellow
        $report += "⚠️  Protección en la nube: DESACTIVADA"
        $warnings++
    }
    
    # Actualizaciones de definiciones
    $signatureAge = (Get-Date) - $defenderStatus.AntivirusSignatureLastUpdated
    if ($signatureAge.TotalDays -le 3) {
        Write-Host "  ✅ Definiciones actualizadas (hace $([math]::Round($signatureAge.TotalHours, 1)) horas)" -ForegroundColor Green
        $report += "✅ Definiciones actualizadas: $(($defenderStatus.AntivirusSignatureLastUpdated).ToString('yyyy-MM-dd HH:mm'))"
        $goodItems++
    } else {
        Write-Host "  ⚠️  Definiciones desactualizadas (hace $([math]::Round($signatureAge.TotalDays, 1)) días)" -ForegroundColor Yellow
        $report += "⚠️  Definiciones desactualizadas: $(($defenderStatus.AntivirusSignatureLastUpdated).ToString('yyyy-MM-dd HH:mm'))"
        $warnings++
    }
    
    # Escaneo rápido
    $quickScanAge = (Get-Date) - $defenderStatus.QuickScanAge
    if ($quickScanAge.TotalDays -le 7) {
        Write-Host "  ✅ Último escaneo rápido: hace $([math]::Round($quickScanAge.TotalDays, 1)) días" -ForegroundColor Green
        $report += "✅ Último escaneo rápido: hace $([math]::Round($quickScanAge.TotalDays, 1)) días"
        $goodItems++
    } else {
        Write-Host "  ⚠️  Sin escaneo rápido reciente (hace $([math]::Round($quickScanAge.TotalDays, 1)) días)" -ForegroundColor Yellow
        $report += "⚠️  Sin escaneo rápido reciente (hace $([math]::Round($quickScanAge.TotalDays, 1)) días)"
        $warnings++
    }
    
    Write-Log "Windows Defender: Real-time=$($defenderStatus.RealTimeProtectionEnabled), Cloud=$($defenderStatus.CloudProtectionEnabled)" -Level "INFO"
    
} catch {
    Write-Host "  ❌ No se pudo verificar Windows Defender" -ForegroundColor Red
    $report += "❌ Error al verificar Windows Defender"
    $criticalIssues++
    Write-Log "Error al verificar Defender: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 2. FIREWALL DE WINDOWS
# ============================================

Write-Host "[2/7] Analizando Firewall..." -ForegroundColor Cyan

$report += "2. FIREWALL DE WINDOWS"
$report += "-" * 50

try {
    $firewallProfiles = Get-NetFirewallProfile -ErrorAction Stop
    
    foreach ($profile in $firewallProfiles) {
        $profileName = $profile.Name
        if ($profile.Enabled) {
            Write-Host "  ✅ Perfil $profileName : ACTIVO" -ForegroundColor Green
            $report += "✅ Perfil $profileName : ACTIVO"
            $goodItems++
        } else {
            Write-Host "  ❌ Perfil $profileName : DESACTIVADO" -ForegroundColor Red
            $report += "❌ Perfil $profileName : DESACTIVADO"
            $criticalIssues++
        }
    }
    
    Write-Log "Firewall verificado: Todos los perfiles analizados" -Level "INFO"
    
} catch {
    Write-Host "  ❌ No se pudo verificar el Firewall" -ForegroundColor Red
    $report += "❌ Error al verificar Firewall"
    $criticalIssues++
    Write-Log "Error al verificar Firewall: $($_.Exception.Message)" -Level "ERROR"
}

$report += ""
Write-Host ""

# ============================================
# 3. WINDOWS UPDATE
# ============================================

Write-Host "[3/7] Verificando actualizaciones..." -ForegroundColor Cyan

$report += "3. WINDOWS UPDATE"
$report += "-" * 50

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    
    Write-Host "  🔍 Buscando actualizaciones pendientes..." -ForegroundColor Yellow
    
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
    $pendingUpdates = $searchResult.Updates.Count
    
    if ($pendingUpdates -eq 0) {
        Write-Host "  ✅ Sistema actualizado: 0 actualizaciones pendientes" -ForegroundColor Green
        $report += "✅ Sistema actualizado: 0 actualizaciones pendientes"
        $goodItems++
    } elseif ($pendingUpdates -le 5) {
        Write-Host "  ⚠️  Actualizaciones pendientes: $pendingUpdates" -ForegroundColor Yellow
        $report += "⚠️  Actualizaciones pendientes: $pendingUpdates"
        $warnings++
    } else {
        Write-Host "  ❌ Muchas actualizaciones pendientes: $pendingUpdates" -ForegroundColor Red
        $report += "❌ Actualizaciones pendientes: $pendingUpdates"
        $criticalIssues++
    }
    
    # Listar actualizaciones importantes
    if ($pendingUpdates -gt 0) {
        $report += ""
        $report += "Actualizaciones importantes:"
        $count = 0
        foreach ($update in $searchResult.Updates) {
            if ($update.AutoSelectOnWebSites -or $update.IsMandatory) {
                $report += "  • $($update.Title)"
                $count++
                if ($count -ge 5) { break }
            }
        }
    }
    
    Write-Log "Windows Update: $pendingUpdates actualizaciones pendientes" -Level "INFO"
    
} catch {
    Write-Host "  ⚠️  No se pudo verificar Windows Update" -ForegroundColor Yellow
    $report += "⚠️  Error al verificar Windows Update"
    $warnings++
    Write-Log "Error al verificar Windows Update: $($_.Exception.Message)" -Level "WARNING"
}

$report += ""
Write-Host ""

# ============================================
# 4. CONTROL DE CUENTAS DE USUARIO (UAC)
# ============================================

Write-Host "[4/7] Verificando UAC..." -ForegroundColor Cyan

$report += "4. CONTROL DE CUENTAS DE USUARIO (UAC)"
$report += "-" * 50

try {
    $uacValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction Stop
    
    if ($uacValue.EnableLUA -eq 1) {
        Write-Host "  ✅ UAC: ACTIVADO" -ForegroundColor Green
        $report += "✅ UAC: ACTIVADO"
        $goodItems++
    } else {
        Write-Host "  ❌ UAC: DESACTIVADO" -ForegroundColor Red
        $report += "❌ UAC: DESACTIVADO (Riesgo de seguridad)"
        $criticalIssues++
    }
    
    Write-Log "UAC verificado: EnableLUA=$($uacValue.EnableLUA)" -Level "INFO"
    
} catch {
    Write-Host "  ⚠️  No se pudo verificar UAC" -ForegroundColor Yellow
    $report += "⚠️  Error al verificar UAC"
    $warnings++
}

$report += ""
Write-Host ""

# ============================================
# 5. BITLOCKER (CIFRADO DE DISCO)
# ============================================

Write-Host "[5/7] Verificando BitLocker..." -ForegroundColor Cyan

$report += "5. BITLOCKER (CIFRADO DE DISCO)"
$report += "-" * 50

try {
    $bitlockerVolumes = Get-BitLockerVolume -ErrorAction Stop | Where-Object { $_.VolumeType -eq "OperatingSystem" }
    
    if ($bitlockerVolumes) {
        foreach ($volume in $bitlockerVolumes) {
            if ($volume.ProtectionStatus -eq "On") {
                Write-Host "  ✅ BitLocker en $($volume.MountPoint): ACTIVO" -ForegroundColor Green
                $report += "✅ BitLocker en $($volume.MountPoint): ACTIVO ($($volume.EncryptionPercentage)% cifrado)"
                $goodItems++
            } else {
                Write-Host "  ⚠️  BitLocker en $($volume.MountPoint): DESACTIVADO" -ForegroundColor Yellow
                $report += "⚠️  BitLocker en $($volume.MountPoint): DESACTIVADO"
                $warnings++
            }
        }
    } else {
        Write-Host "  ℹ️  BitLocker no está configurado" -ForegroundColor Gray
        $report += "ℹ️  BitLocker no está configurado (Opcional para PCs personales)"
    }
    
    Write-Log "BitLocker verificado" -Level "INFO"
    
} catch {
    Write-Host "  ℹ️  BitLocker no disponible o no se pudo verificar" -ForegroundColor Gray
    $report += "ℹ️  BitLocker no disponible o no se pudo verificar"
}

$report += ""
Write-Host ""

# ============================================
# 6. CUENTAS DE USUARIO
# ============================================

Write-Host "[6/7] Analizando cuentas de usuario..." -ForegroundColor Cyan

$report += "6. CUENTAS DE USUARIO"
$report += "-" * 50

try {
    $localUsers = Get-LocalUser -ErrorAction Stop | Where-Object { $_.Enabled -eq $true }
    # Usar SID en lugar de nombre para compatibilidad con cualquier idioma
    # S-1-5-32-544 = Administrators group
    $adminUsers = Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction Stop
    
    Write-Host "  ℹ️  Cuentas activas: $($localUsers.Count)" -ForegroundColor White
    $report += "Cuentas activas: $($localUsers.Count)"
    
    Write-Host "  ℹ️  Administradores: $($adminUsers.Count)" -ForegroundColor White
    $report += "Administradores: $($adminUsers.Count)"
    
    if ($adminUsers.Count -gt 2) {
        Write-Host "  ⚠️  Múltiples cuentas de administrador detectadas" -ForegroundColor Yellow
        $report += "⚠️  Múltiples cuentas de administrador (revisar permisos)"
        $warnings++
    } else {
        $goodItems++
    }
    
    # Verificar cuenta de invitado
    $guestAccount = Get-LocalUser -Name "Invitado" -ErrorAction SilentlyContinue
    if ($guestAccount -and $guestAccount.Enabled) {
        Write-Host "  ⚠️  Cuenta de invitado ACTIVADA" -ForegroundColor Yellow
        $report += "⚠️  Cuenta de invitado ACTIVADA (Desactivar recomendado)"
        $warnings++
    } else {
        Write-Host "  ✅ Cuenta de invitado: DESACTIVADA" -ForegroundColor Green
        $report += "✅ Cuenta de invitado: DESACTIVADA"
        $goodItems++
    }
    
    Write-Log "Cuentas de usuario verificadas: $($localUsers.Count) activas, $($adminUsers.Count) admins" -Level "INFO"
    
} catch {
    Write-Host "  ⚠️  No se pudo verificar cuentas de usuario" -ForegroundColor Yellow
    $report += "⚠️  Error al verificar cuentas de usuario"
    $warnings++
}

$report += ""
Write-Host ""

# ============================================
# 7. SERVICIOS CRÍTICOS DE SEGURIDAD
# ============================================

Write-Host "[7/7] Verificando servicios de seguridad..." -ForegroundColor Cyan

$report += "7. SERVICIOS CRÍTICOS DE SEGURIDAD"
$report += "-" * 50

$criticalServices = @{
    "WinDefend" = "Windows Defender Antivirus"
    "mpssvc" = "Firewall de Windows"
    "wuauserv" = "Windows Update"
    "EventLog" = "Registro de eventos"
    "CryptSvc" = "Servicios criptográficos"
}

foreach ($svcName in $criticalServices.Keys) {
    $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    
    if ($service) {
        if ($service.Status -eq "Running") {
            Write-Host "  ✅ $($criticalServices[$svcName]): EJECUTÁNDOSE" -ForegroundColor Green
            $report += "✅ $($criticalServices[$svcName]): EJECUTÁNDOSE"
            $goodItems++
        } else {
            Write-Host "  ❌ $($criticalServices[$svcName]): DETENIDO" -ForegroundColor Red
            $report += "❌ $($criticalServices[$svcName]): DETENIDO"
            $criticalIssues++
        }
    } else {
        Write-Host "  ⚠️  $($criticalServices[$svcName]): NO ENCONTRADO" -ForegroundColor Yellow
        $report += "⚠️  $($criticalServices[$svcName]): NO ENCONTRADO"
        $warnings++
    }
}

Write-Log "Servicios de seguridad verificados" -Level "INFO"

$report += ""
Write-Host ""

# ============================================
# RESUMEN
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESUMEN DEL ANÁLISIS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$report += "=================================================="
$report += "RESUMEN DEL ANÁLISIS"
$report += "=================================================="
$report += ""

if ($criticalIssues -eq 0 -and $warnings -eq 0) {
    Write-Host "✅ EXCELENTE: Tu sistema está bien protegido" -ForegroundColor Green
    $report += "✅ ESTADO: EXCELENTE - Sistema bien protegido"
} elseif ($criticalIssues -eq 0) {
    Write-Host "⚠️  BUENO: Algunas advertencias menores" -ForegroundColor Yellow
    $report += "⚠️  ESTADO: BUENO - Algunas advertencias menores"
} elseif ($criticalIssues -le 2) {
    Write-Host "⚠️  ATENCIÓN: Algunos problemas importantes" -ForegroundColor Yellow
    $report += "⚠️  ESTADO: ATENCIÓN - Problemas importantes detectados"
} else {
    Write-Host "❌ CRÍTICO: Tu sistema tiene riesgos de seguridad" -ForegroundColor Red
    $report += "❌ ESTADO: CRÍTICO - Riesgos de seguridad importantes"
}

Write-Host ""
Write-Host "  • Configuraciones correctas: $goodItems" -ForegroundColor Green
Write-Host "  • Advertencias: $warnings" -ForegroundColor Yellow
Write-Host "  • Problemas críticos: $criticalIssues" -ForegroundColor Red

$report += ""
$report += "ESTADÍSTICAS:"
$report += "  • Configuraciones correctas: $goodItems"
$report += "  • Advertencias: $warnings"
$report += "  • Problemas críticos: $criticalIssues"

Write-Host ""
Write-Host "📄 Reporte guardado en:" -ForegroundColor Cyan
Write-Host "   $reportPath" -ForegroundColor Gray

# Guardar reporte
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Log "Análisis de seguridad completado: $goodItems OK, $warnings warnings, $criticalIssues critical" -Level "SUCCESS"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

# ============================================
# Gestor-Actualizaciones.ps1
# Control avanzado de Windows Update
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GESTOR DE ACTUALIZACIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Log "Gestor de actualizaciones cancelado: Sin permisos" -Level "ERROR"
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Log "Iniciando gestor de actualizaciones" -Level "INFO"

# Función para pausar actualizaciones
function Pause-Updates {
    Write-Host ""
    Write-Host "⏸️  PAUSANDO ACTUALIZACIONES..." -ForegroundColor Yellow
    Write-Host ""
    
    $dias = Read-Host "¿Por cuántos días pausar? (1-35, recomendado: 7)"
    
    if ($dias -match '^\d+$' -and [int]$dias -ge 1 -and [int]$dias -le 35) {
        $expiryDate = (Get-Date).AddDays([int]$dias).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -Value $expiryDate -Force
            
            Write-Host "  ✅ Actualizaciones pausadas por $dias días" -ForegroundColor Green
            Write-Host "  📅 Se reanudarán el: $((Get-Date).AddDays([int]$dias).ToString('dd/MM/yyyy'))" -ForegroundColor Cyan
            Write-Log "Actualizaciones pausadas por $dias días" -Level "INFO"
            
        } catch {
            Write-Host "  ❌ Error al pausar actualizaciones: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ Número de días inválido" -ForegroundColor Red
    }
}

# Función para reanudar actualizaciones
function Resume-Updates {
    Write-Host ""
    Write-Host "▶️  REANUDANDO ACTUALIZACIONES..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        
        if (Test-Path $regPath) {
            Remove-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "PauseQualityUpdatesExpiryTime" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesExpiryTime" -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "  ✅ Actualizaciones reanudadas" -ForegroundColor Green
        Write-Host "  ℹ️  Windows buscará actualizaciones automáticamente" -ForegroundColor Cyan
        Write-Log "Actualizaciones reanudadas" -Level "INFO"
        
    } catch {
        Write-Host "  ❌ Error al reanudar actualizaciones: $_" -ForegroundColor Red
    }
}

# Función para ver historial de actualizaciones
function Show-UpdateHistory {
    Write-Host ""
    Write-Host "📜 HISTORIAL DE ACTUALIZACIONES" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    try {
        $updates = Get-WmiObject -Class Win32_QuickFixEngineering | 
                   Sort-Object -Property InstalledOn -Descending |
                   Select-Object -First 20
        
        if ($updates) {
            foreach ($update in $updates) {
                $date = "N/A"
                if ($update.InstalledOn) {
                    try {
                        $date = ([DateTime]$update.InstalledOn).ToString("dd/MM/yyyy")
                    } catch {
                        $date = $update.InstalledOn
                    }
                }
                
                Write-Host "  📦 $($update.HotFixID) " -NoNewline -ForegroundColor Yellow
                Write-Host "- $($update.Description)" -ForegroundColor White
                Write-Host "     📅 Instalado: $date" -ForegroundColor Gray
                Write-Host ""
            }
            
            Write-Host "  Total de actualizaciones recientes: $($updates.Count)" -ForegroundColor Cyan
        } else {
            Write-Host "  ℹ️  No se encontró historial de actualizaciones" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ❌ Error al obtener historial: $_" -ForegroundColor Red
    }
}

# Función para buscar actualizaciones disponibles
function Search-AvailableUpdates {
    Write-Host ""
    Write-Host "🔍 BUSCANDO ACTUALIZACIONES DISPONIBLES..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ⏳ Esto puede tardar varios minutos..." -ForegroundColor Gray
    Write-Host ""
    
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
        
        if ($searchResult.Updates.Count -gt 0) {
            Write-Host "  ✅ Se encontraron $($searchResult.Updates.Count) actualizaciones disponibles:" -ForegroundColor Green
            Write-Host ""
            
            $index = 1
            $global:availableUpdates = @()
            
            foreach ($update in $searchResult.Updates) {
                $sizeKB = [math]::Round($update.MaxDownloadSize / 1024, 0)
                $sizeMB = [math]::Round($sizeKB / 1024, 1)
                
                $severity = switch ($update.MsrcSeverity) {
                    "Critical" { "🔴 Crítica" }
                    "Important" { "🟠 Importante" }
                    "Moderate" { "🟡 Moderada" }
                    "Low" { "🟢 Baja" }
                    default { "⚪ No especificada" }
                }
                
                Write-Host "  [$index] " -NoNewline -ForegroundColor White
                Write-Host "$($update.Title)" -ForegroundColor Yellow
                Write-Host "      Tamaño: $sizeMB MB | Severidad: $severity" -ForegroundColor Gray
                Write-Host ""
                
                $global:availableUpdates += $update
                $index++
            }
            
            Write-Host ""
            Write-Host "  💡 ¿Deseas instalar estas actualizaciones?" -ForegroundColor Cyan
            Write-Host "     [1] Instalar todas" -ForegroundColor Green
            Write-Host "     [2] Seleccionar específicas" -ForegroundColor Yellow
            Write-Host "     [0] Cancelar" -ForegroundColor Gray
            Write-Host ""
            
            $choice = Read-Host "Opción"
            
            if ($choice -eq '1') {
                Install-SelectedUpdates -Updates $global:availableUpdates
            } elseif ($choice -eq '2') {
                Select-SpecificUpdates
            } else {
                Write-Host "  ℹ️  Instalación cancelada" -ForegroundColor Gray
            }
            
        } else {
            Write-Host "  ✅ No hay actualizaciones disponibles" -ForegroundColor Green
            Write-Host "  ℹ️  Tu sistema está actualizado" -ForegroundColor Cyan
        }
        
    } catch {
        Write-Host "  ❌ Error al buscar actualizaciones: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "  💡 Puedes usar Windows Update desde Configuración:" -ForegroundColor Yellow
        Write-Host "     Inicio > Configuración > Actualización y Seguridad" -ForegroundColor Gray
    }
}

# Función para seleccionar actualizaciones específicas
function Select-SpecificUpdates {
    Write-Host ""
    Write-Host "  Ingresa los números de las actualizaciones a instalar (separados por coma)" -ForegroundColor Cyan
    Write-Host "  Ejemplo: 1,3,5" -ForegroundColor Gray
    Write-Host ""
    
    $selection = Read-Host "Selección"
    $numbers = $selection -split ',' | ForEach-Object { $_.Trim() }
    
    $selectedUpdates = @()
    foreach ($num in $numbers) {
        if ($num -match '^\d+$') {
            $index = [int]$num - 1
            if ($index -ge 0 -and $index -lt $global:availableUpdates.Count) {
                $selectedUpdates += $global:availableUpdates[$index]
            }
        }
    }
    
    if ($selectedUpdates.Count -gt 0) {
        Write-Host ""
        Write-Host "  Actualizaciones seleccionadas: $($selectedUpdates.Count)" -ForegroundColor Cyan
        Install-SelectedUpdates -Updates $selectedUpdates
    } else {
        Write-Host "  ❌ No se seleccionaron actualizaciones válidas" -ForegroundColor Red
    }
}

# Función para instalar actualizaciones
function Install-SelectedUpdates {
    param([array]$Updates)
    
    Write-Host ""
    Write-Host "  📥 INSTALANDO ACTUALIZACIONES..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
        
        foreach ($update in $Updates) {
            $updateCollection.Add($update) | Out-Null
        }
        
        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updateCollection
        
        Write-Host "  ⏳ Descargando actualizaciones..." -ForegroundColor Cyan
        $downloadResult = $downloader.Download()
        
        if ($downloadResult.ResultCode -eq 2) {
            Write-Host "  ✅ Descarga completada" -ForegroundColor Green
            
            Write-Host "  ⏳ Instalando actualizaciones..." -ForegroundColor Cyan
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $updateCollection
            
            $installResult = $installer.Install()
            
            if ($installResult.ResultCode -eq 2) {
                Write-Host "  ✅ Instalación completada exitosamente" -ForegroundColor Green
                Write-Log "Instaladas $($Updates.Count) actualizaciones" -Level "SUCCESS"
                
                if ($installResult.RebootRequired) {
                    Write-Host ""
                    Write-Host "  ⚠️  SE REQUIERE REINICIAR EL EQUIPO" -ForegroundColor Yellow
                    Write-Host ""
                    $reboot = Read-Host "  ¿Reiniciar ahora? (S/N)"
                    if ($reboot -eq 'S' -or $reboot -eq 's') {
                        Write-Host "  🔄 Reiniciando en 30 segundos..." -ForegroundColor Yellow
                        shutdown /r /t 30
                    }
                }
            } else {
                Write-Host "  ⚠️  Instalación completada con errores (código: $($installResult.ResultCode))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ❌ Error en la descarga (código: $($downloadResult.ResultCode))" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "  ❌ Error durante la instalación: $_" -ForegroundColor Red
    }
}

# Función para ocultar/mostrar actualizaciones
function Hide-Updates {
    Write-Host ""
    Write-Host "🙈 OCULTAR ACTUALIZACIONES ESPECÍFICAS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ⚠️  Esta función está en desarrollo" -ForegroundColor Yellow
    Write-Host "  💡 Para ocultar actualizaciones, usa:" -ForegroundColor Cyan
    Write-Host "     Configuración > Actualización y Seguridad > Ver historial de actualizaciones" -ForegroundColor Gray
}

# Función para verificar estado actual
function Show-UpdateStatus {
    Write-Host ""
    Write-Host "📊 ESTADO DE ACTUALIZACIONES" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Verificar si están pausadas
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        $pauseTime = Get-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
        
        if ($pauseTime) {
            try {
                $expiryDate = [DateTime]::Parse($pauseTime.PauseUpdatesExpiryTime)
                if ($expiryDate -gt (Get-Date)) {
                    $daysRemaining = ($expiryDate - (Get-Date)).Days
                    Write-Host "  🟡 Estado: PAUSADAS" -ForegroundColor Yellow
                    Write-Host "  📅 Se reanudarán: $($expiryDate.ToString('dd/MM/yyyy'))" -ForegroundColor Cyan
                    Write-Host "  ⏳ Días restantes: $daysRemaining" -ForegroundColor Gray
                } else {
                    Write-Host "  🟢 Estado: ACTIVAS" -ForegroundColor Green
                }
            } catch {
                Write-Host "  🟢 Estado: ACTIVAS" -ForegroundColor Green
            }
        } else {
            Write-Host "  🟢 Estado: ACTIVAS" -ForegroundColor Green
        }
    } catch {
        Write-Host "  🟢 Estado: ACTIVAS (por defecto)" -ForegroundColor Green
    }
    
    # Última búsqueda
    try {
        $lastSearch = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "LastSearchSuccessTime" -ErrorAction SilentlyContinue
        if ($lastSearch) {
            Write-Host "  🔍 Última búsqueda: $($lastSearch.LastSearchSuccessTime)" -ForegroundColor Gray
        }
    } catch { }
    
    # Total de actualizaciones instaladas
    try {
        $totalUpdates = (Get-WmiObject -Class Win32_QuickFixEngineering).Count
        Write-Host "  📦 Actualizaciones instaladas: $totalUpdates" -ForegroundColor Cyan
    } catch { }
    
    Write-Host ""
}

# Menú principal
while ($true) {
    Write-Host ""
    Write-Host "MENÚ DE OPCIONES:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] 📊 Ver estado actual" -ForegroundColor Cyan
    Write-Host "  [2] ⏸️  Pausar actualizaciones" -ForegroundColor Yellow
    Write-Host "  [3] ▶️  Reanudar actualizaciones" -ForegroundColor Green
    Write-Host "  [4] 🔍 Buscar actualizaciones disponibles" -ForegroundColor Cyan
    Write-Host "  [5] 📜 Ver historial de actualizaciones" -ForegroundColor Blue
    Write-Host "  [6] 🙈 Ocultar actualizaciones específicas" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  [0] Salir" -ForegroundColor Gray
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción (0-6)"
    
    switch ($opcion) {
        '1' { Show-UpdateStatus }
        '2' { Pause-Updates }
        '3' { Resume-Updates }
        '4' { Search-AvailableUpdates }
        '5' { Show-UpdateHistory }
        '6' { Hide-Updates }
        '0' {
            Write-Host ""
            Write-Host "Saliendo..." -ForegroundColor Gray
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
            exit
        }
        default {
            Write-Host ""
            Write-Host "❌ Opción no válida" -ForegroundColor Red
        }
    }
}

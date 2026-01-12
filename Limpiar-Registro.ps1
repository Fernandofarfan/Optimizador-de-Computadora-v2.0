# ============================================
# Limpiar-Registro.ps1
# Limpieza segura del registro de Windows
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LIMPIEZA SEGURA DE REGISTRO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Log "Limpieza de registro cancelada: Sin permisos" -Level "ERROR"
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
    exit
}

Write-Log "Iniciando limpieza de registro" -Level "INFO"

# Variables de contadores
$entradasAnalizadas = 0
$entradasEliminadas = 0
$errores = 0
$espacioLiberado = 0

# Crear backup del registro
$backupFolder = "$scriptPath\Backup-Registro"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "$backupFolder\Backup-$timestamp"

if (-not (Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $backupPath)) {
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
}

Write-Host "🔐 CREANDO BACKUP DEL REGISTRO..." -ForegroundColor Yellow
Write-Host ""

# Exportar claves antes de limpiar
$keysToBakcup = @(
    @{Path = "HKCU:\Software\Classes\Local Settings"; Name = "MuiCache"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"; Name = "SharedDLLs"},
    @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"; Name = "FileExts"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"; Name = "Uninstall"},
    @{Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"; Name = "Uninstall32"}
)

foreach ($key in $keysToBakcup) {
    $regPath = $key.Path -replace "HKCU:\\", "HKEY_CURRENT_USER\" -replace "HKLM:\\", "HKEY_LOCAL_MACHINE\"
    $backupFile = "$backupPath\$($key.Name).reg"
    
    Write-Host "  Exportando: $($key.Name)..." -ForegroundColor Gray
    $result = Start-Process "reg" -ArgumentList "export `"$regPath`" `"$backupFile`" /y" -Wait -PassThru -WindowStyle Hidden
    
    if ($result.ExitCode -eq 0) {
        Write-Host "    ✅ Backup creado" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️ No se pudo crear backup (puede ser normal)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Backups guardados en: $backupPath" -ForegroundColor Green
Write-Host ""

# Función para limpiar MUICache (caché de iconos)
function Clean-MUICache {
    Write-Host "[1/5] 🗂️  Limpiando MUICache..." -ForegroundColor Cyan
    
    $muiPaths = @(
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache",
        "HKCU:\Software\Classes\Local Settings\MuiCache"
    )
    
    $cleaned = 0
    foreach ($path in $muiPaths) {
        if (Test-Path $path) {
            $items = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    $script:entradasAnalizadas++
                    Remove-Item -Path $item.PSPath -Force -Recurse
                    $cleaned++
                    $script:entradasEliminadas++
                } catch {
                    $script:errores++
                }
            }
        }
    }
    
    Write-Host "  ✅ Entradas eliminadas: $cleaned" -ForegroundColor Green
    Write-Log "MUICache limpiado: $cleaned entradas" -Level "INFO"
}

# Función para limpiar SharedDLLs huérfanas
function Clean-SharedDLLs {
    Write-Host "[2/5] 📚 Limpiando SharedDLLs..." -ForegroundColor Cyan
    
    $dllPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedDLLs"
    
    if (Test-Path $dllPath) {
        $dlls = Get-ItemProperty -Path $dllPath
        $cleaned = 0
        
        foreach ($prop in $dlls.PSObject.Properties) {
            if ($prop.Name -like "*.dll" -or $prop.Name -like "*.exe") {
                $script:entradasAnalizadas++
                
                # Verificar si el archivo existe
                if (-not (Test-Path $prop.Name)) {
                    try {
                        Remove-ItemProperty -Path $dllPath -Name $prop.Name -Force
                        $cleaned++
                        $script:entradasEliminadas++
                    } catch {
                        $script:errores++
                    }
                }
            }
        }
        
        Write-Host "  ✅ DLLs huérfanas eliminadas: $cleaned" -ForegroundColor Green
        Write-Log "SharedDLLs limpiado: $cleaned entradas" -Level "INFO"
    } else {
        Write-Host "  ℹ️  Clave no encontrada" -ForegroundColor Gray
    }
}

# Función para limpiar extensiones de archivo inválidas
function Clean-FileExts {
    Write-Host "[3/5] 📄 Limpiando extensiones de archivo..." -ForegroundColor Cyan
    
    $extsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
    
    if (Test-Path $extsPath) {
        $extensions = Get-ChildItem -Path $extsPath -ErrorAction SilentlyContinue
        $cleaned = 0
        
        foreach ($ext in $extensions) {
            $script:entradasAnalizadas++
            
            # Verificar si tiene subclaves válidas
            $userChoice = Get-ItemProperty -Path "$($ext.PSPath)\UserChoice" -ErrorAction SilentlyContinue
            $openWithList = Get-ChildItem -Path "$($ext.PSPath)\OpenWithList" -ErrorAction SilentlyContinue
            
            # Si no tiene UserChoice ni OpenWithList, probablemente está huérfana
            if (-not $userChoice -and -not $openWithList) {
                try {
                    Remove-Item -Path $ext.PSPath -Recurse -Force
                    $cleaned++
                    $script:entradasEliminadas++
                } catch {
                    $script:errores++
                }
            }
        }
        
        Write-Host "  ✅ Extensiones huérfanas eliminadas: $cleaned" -ForegroundColor Green
        Write-Log "FileExts limpiado: $cleaned entradas" -Level "INFO"
    } else {
        Write-Host "  ℹ️  Clave no encontrada" -ForegroundColor Gray
    }
}

# Función para limpiar claves de desinstalación huérfanas
function Clean-UninstallKeys {
    Write-Host "[4/5] 🗑️  Limpiando claves de desinstalación..." -ForegroundColor Cyan
    
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    $cleaned = 0
    
    foreach ($path in $uninstallPaths) {
        if (Test-Path $path) {
            $programs = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            
            foreach ($program in $programs) {
                $script:entradasAnalizadas++
                
                $props = Get-ItemProperty -Path $program.PSPath
                
                # Verificar si tiene InstallLocation o UninstallString
                if ($props.InstallLocation -or $props.UninstallString) {
                    $installPath = $props.InstallLocation
                    $uninstallPath = $props.UninstallString
                    
                    # Si InstallLocation existe pero el directorio no
                    if ($installPath -and -not (Test-Path $installPath)) {
                        try {
                            Remove-Item -Path $program.PSPath -Recurse -Force
                            $cleaned++
                            $script:entradasEliminadas++
                        } catch {
                            $script:errores++
                        }
                    }
                    # Si UninstallString apunta a un archivo que no existe
                    elseif ($uninstallPath) {
                        # Extraer ruta del ejecutable
                        $exePath = $uninstallPath -replace '"', '' -split ' ' | Select-Object -First 1
                        if ($exePath -and -not (Test-Path $exePath)) {
                            try {
                                Remove-Item -Path $program.PSPath -Recurse -Force
                                $cleaned++
                                $script:entradasEliminadas++
                            } catch {
                                $script:errores++
                            }
                        }
                    }
                }
            }
        }
    }
    
    Write-Host "  ✅ Claves de desinstalación huérfanas: $cleaned" -ForegroundColor Green
    Write-Log "Claves Uninstall limpiadas: $cleaned entradas" -Level "INFO"
}

# Función para limpiar documentos recientes
function Clean-RecentDocs {
    Write-Host "[5/5] 📋 Limpiando documentos recientes..." -ForegroundColor Cyan
    
    $recentPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
    )
    
    $cleaned = 0
    
    foreach ($path in $recentPaths) {
        if (Test-Path $path) {
            $items = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    $script:entradasAnalizadas++
                    Remove-Item -Path $item.PSPath -Force -Recurse
                    $cleaned++
                    $script:entradasEliminadas++
                } catch {
                    $script:errores++
                }
            }
            
            # Limpiar propiedades de la clave raíz
            $props = Get-ItemProperty -Path $path
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -notlike "PS*") {
                    try {
                        Remove-ItemProperty -Path $path -Name $prop.Name -Force
                        $cleaned++
                        $script:entradasEliminadas++
                    } catch {
                        $script:errores++
                    }
                }
            }
        }
    }
    
    Write-Host "  ✅ Documentos recientes eliminados: $cleaned" -ForegroundColor Green
    Write-Log "Documentos recientes limpiados: $cleaned entradas" -Level "INFO"
}

# Ejecutar limpieza
Write-Host "🧹 INICIANDO LIMPIEZA..." -ForegroundColor Yellow
Write-Host ""

Clean-MUICache
Clean-SharedDLLs
Clean-FileExts
Clean-UninstallKeys
Clean-RecentDocs

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTADOS DE LA LIMPIEZA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Estadísticas:" -ForegroundColor White
Write-Host ""
Write-Host "  Entradas analizadas:  " -NoNewline -ForegroundColor Gray
Write-Host "$entradasAnalizadas" -ForegroundColor Yellow
Write-Host "  Entradas eliminadas:  " -NoNewline -ForegroundColor Gray
Write-Host "$entradasEliminadas" -ForegroundColor Green
Write-Host "  Errores encontrados:  " -NoNewline -ForegroundColor Gray
Write-Host "$errores" -ForegroundColor Red
Write-Host ""

if ($entradasEliminadas -gt 0) {
    $espacioEstimado = [math]::Round(($entradasEliminadas * 2) / 1024, 2) # Estimación 2KB por entrada
    Write-Host "  Espacio liberado:     " -NoNewline -ForegroundColor Gray
    Write-Host "~$espacioEstimado MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ LIMPIEZA COMPLETADA" -ForegroundColor Green
Write-Log "Limpieza completada: $entradasEliminadas entradas eliminadas, $errores errores" -Level "SUCCESS"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "💡 INFORMACIÓN DE BACKUP:" -ForegroundColor Cyan
Write-Host "  Backup guardado en: $backupPath" -ForegroundColor White
Write-Host ""
Write-Host "  Para restaurar el registro:" -ForegroundColor Yellow
Write-Host "  1. Navega a la carpeta de backup" -ForegroundColor Gray
Write-Host "  2. Haz doble clic en el archivo .reg que desees restaurar" -ForegroundColor Gray
Write-Host "  3. Confirma la importación" -ForegroundColor Gray
Write-Host ""
Write-Host "🔒 ÁREAS SEGURAS LIMPIADAS:" -ForegroundColor Cyan
Write-Host "  • MUICache (caché de iconos y menús)" -ForegroundColor White
Write-Host "  • SharedDLLs huérfanas (bibliotecas no utilizadas)" -ForegroundColor White
Write-Host "  • Extensiones de archivo inválidas" -ForegroundColor White
Write-Host "  • Claves de desinstalación huérfanas" -ForegroundColor White
Write-Host "  • Documentos y carpetas recientes" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  ÁREAS NO TOCADAS (seguridad):" -ForegroundColor Yellow
Write-Host "  • HKLM\SYSTEM (sistema crítico)" -ForegroundColor Gray
Write-Host "  • CurrentVersion\Run (inicio de Windows)" -ForegroundColor Gray
Write-Host "  • Drivers y servicios" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

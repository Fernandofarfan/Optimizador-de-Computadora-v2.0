<#
.SYNOPSIS
    Optimizador de Computadora - Suite de Mantenimiento
    Autor: Proyecto de Optimizacion
    Fecha: 2026

.DESCRIPTION
    Script maestro que gestiona el análisis, limpieza y optimización del sistema.
    Diseñado para ser seguro, eficiente y fácil de usar.
#>

$ErrorActionPreference = 'SilentlyContinue'
# Forzar que el directorio de trabajo sea donde esta el script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

$title = "OPTIMIZADOR DE COMPUTADORA v2.6"

# --- Funciones Auxiliares ---

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                  $title" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Usuario: $env:USERNAME" -ForegroundColor Gray
    Write-Host "  Fecha:   $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        Write-Host "  Permisos: ADMINISTRADOR (Correcto)" -ForegroundColor Green
    } else {
        Write-Host "  Permisos: USUARIO (Algunas funciones limitadas)" -ForegroundColor Yellow
        Write-Host "  * Se recomienda ejecutar PowerShell como Administrador *" -ForegroundColor DarkYellow
    }
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Wait-Key {
    Write-Host "`nPresiona cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# --- Menú Principal ---

do {
    Show-Header
    Write-Host "SELECCIONA UNA OPCION:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] ANALIZAR SISTEMA" -ForegroundColor Green
    Write-Host "      (Ver estado de RAM, CPU, Disco y recomendaciones)"
    Write-Host ""
    Write-Host "  [2] LIMPIEZA RAPIDA (Segura)" -ForegroundColor Green
    Write-Host "      (Borra temporales de usuario y cache de navegadores)"
    Write-Host ""
    Write-Host "  [3] LIMPIEZA PROFUNDA (Requiere Admin)" -ForegroundColor Yellow
    Write-Host "      (Temporales de Sistema, Windows Update, Logs, Papelera)"
    Write-Host ""
    Write-Host "  [4] OPTIMIZAR SERVICIOS (Boost Rendimiento)" -ForegroundColor Yellow
    Write-Host "      (Desactiva Telemetria, SysMain, Busqueda indebida)"
    Write-Host ""
    Write-Host "  [5] GESTIONAR INICIO Y PROCESOS (Boost arranque)" -ForegroundColor Magenta
    Write-Host "      (Ver y desactivar programas que ralentizan el arranque)"
    Write-Host ""
    Write-Host "  [6] REPARAR Y RED (Herramientas Avanzadas)" -ForegroundColor Cyan
    Write-Host "      (Optimizar Internet, Reparar Windows, SFC, Defrag)"
    Write-Host ""
    Write-Host "  [7] 🔒 ANALIZAR SEGURIDAD" -ForegroundColor Blue
    Write-Host "      (Auditoría completa: Defender, Firewall, Updates, UAC)"
    Write-Host ""
    Write-Host "  [8] 🔄 REVERTIR CAMBIOS (Deshacer optimizaciones)" -ForegroundColor DarkYellow
    Write-Host "      (Reactiva servicios, limpia logs, muestra restore points)"
    Write-Host ""
    Write-Host "  [9] 🎮 MODO GAMING (Alto Rendimiento)" -ForegroundColor Magenta
    Write-Host "      (Pausar updates, optimizar RAM, deshabilitar notificaciones)"
    Write-Host ""
    Write-Host "  [10] 💻 ANÁLISIS HARDWARE" -ForegroundColor Cyan
    Write-Host "       (CPU, RAM, GPU, Disco con SMART, Benchmark)"
    Write-Host ""
    Write-Host "  [11] ⏰ TAREAS PROGRAMADAS" -ForegroundColor Yellow
    Write-Host "       (Automatizar limpieza, seguridad, backups)"
    Write-Host ""
    Write-Host "  [12] 🌐 RED AVANZADA" -ForegroundColor Blue
    Write-Host "       (Speedtest, DNS Benchmark, MTU, Optimizaciones)"
    Write-Host ""
    Write-Host "  [13] 📊 COMPARAR RENDIMIENTO" -ForegroundColor Green
    Write-Host "       (Snapshots antes/después, métricas de mejora)"
    Write-Host ""
    Write-Host "  [14] 🔍 DIAGNÓSTICO AUTOMÁTICO" -ForegroundColor Magenta
    Write-Host "       (Detección inteligente de problemas del sistema)"
    Write-Host ""
    Write-Host "  [15] 💾 BACKUP DE DRIVERS" -ForegroundColor Yellow
    Write-Host "       (Exportar todos los drivers instalados)"
    Write-Host ""
    Write-Host "  [16] 🦠 LIMPIAR MALWARE" -ForegroundColor Red
    Write-Host "       (Detectar y limpiar PUPs, adware, malware)"
    Write-Host ""
    Write-Host "  [17] 📄 GENERAR REPORTE PDF" -ForegroundColor Cyan
    Write-Host "       (Crear reporte profesional del sistema)"
    Write-Host ""
    Write-Host "  [18] 📊 HISTORIAL" -ForegroundColor Blue
    Write-Host "       (Ver historial de optimizaciones)"
    Write-Host ""
    Write-Host "  [0] SALIR" -ForegroundColor Gray
    Write-Host ""
    
    $input = Read-Host "  Ingrese numero > "

    switch ($input) {
        '1' {
            if (Test-Path ".\Analizar-Sistema.ps1") { 
                & ".\Analizar-Sistema.ps1" 
            } else { Write-Host "Error: No se encuentra Analizar-Sistema.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '2' {
             if (Test-Path ".\Optimizar-Sistema-Seguro.ps1") { 
                & ".\Optimizar-Sistema-Seguro.ps1" 
            } else { Write-Host "Error: No se encuentra Optimizar-Sistema-Seguro.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '3' {
            # Verificar Admin antes de ejecutar limpieza profunda
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Limpieza Profunda." -ForegroundColor Red
                Wait-Key
            } else {
                 if (Test-Path ".\Limpieza-Profunda.ps1") { 
                    & ".\Limpieza-Profunda.ps1" 
                } else { Write-Host "Error: No se encuentra Limpieza-Profunda.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '4' {
            # Verificar Admin
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Optimizar Servicios." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Optimizar-Servicios.ps1") { 
                    & ".\Optimizar-Servicios.ps1" 
                } else { Write-Host "Error: No se encuentra Optimizar-Servicios.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '5' {
             if (Test-Path ".\Gestionar-Procesos.ps1") { 
                & ".\Gestionar-Procesos.ps1" 
            } else { Write-Host "Error: No se encuentra Gestionar-Procesos.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '6' {
             $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
             if ($isAdmin) {
                if (Test-Path ".\Reparar-Red-Sistema.ps1") { 
                    & ".\Reparar-Red-Sistema.ps1" 
                } else { Write-Host "Error: No se encuentra Reparar-Red-Sistema.ps1" -ForegroundColor Red }
             } else {
                 Write-Host "Se requieren permisos de Administrador para Reparación Avanzada." -ForegroundColor Red
             }
            Wait-Key
        }
        '7' {
            if (Test-Path ".\Analizar-Seguridad.ps1") { 
                & ".\Analizar-Seguridad.ps1" 
            } else { Write-Host "Error: No se encuentra Analizar-Seguridad.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '8' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Revertir Cambios." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Revertir-Cambios.ps1") { 
                    & ".\Revertir-Cambios.ps1" 
                } else { Write-Host "Error: No se encuentra Revertir-Cambios.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '9' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Modo Gaming." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Optimizar-ModoGaming.ps1") { 
                    & ".\Optimizar-ModoGaming.ps1" 
                } else { Write-Host "Error: No se encuentra Optimizar-ModoGaming.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '10' {
            if (Test-Path ".\Analizar-Hardware.ps1") { 
                & ".\Analizar-Hardware.ps1" 
            } else { Write-Host "Error: No se encuentra Analizar-Hardware.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '11' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Tareas Programadas." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Crear-TareasProgramadas.ps1") { 
                    & ".\Crear-TareasProgramadas.ps1" 
                } else { Write-Host "Error: No se encuentra Crear-TareasProgramadas.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '12' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Red Avanzada." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Optimizar-Red-Avanzada.ps1") { 
                    & ".\Optimizar-Red-Avanzada.ps1" 
                } else { Write-Host "Error: No se encuentra Optimizar-Red-Avanzada.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '13' {
            if (Test-Path ".\Comparar-Rendimiento.ps1") { 
                & ".\Comparar-Rendimiento.ps1" 
            } else { Write-Host "Error: No se encuentra Comparar-Rendimiento.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '14' {
            if (Test-Path ".\Diagnostico-Automatico.ps1") { 
                & ".\Diagnostico-Automatico.ps1" 
            } else { Write-Host "Error: No se encuentra Diagnostico-Automatico.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '15' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Backup de Drivers." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Backup-Drivers.ps1") { 
                    & ".\Backup-Drivers.ps1" 
                } else { Write-Host "Error: No se encuentra Backup-Drivers.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '16' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nAdvertencia: Se recomienda ejecutar como Administrador para mejores resultados." -ForegroundColor Yellow
            }
            if (Test-Path ".\Limpiar-Malware.ps1") { 
                & ".\Limpiar-Malware.ps1" 
            } else { Write-Host "Error: No se encuentra Limpiar-Malware.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '17' {
            if (Test-Path ".\Generar-Reporte-PDF.ps1") { 
                & ".\Generar-Reporte-PDF.ps1" 
            } else { Write-Host "Error: No se encuentra Generar-Reporte-PDF.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '18' {
            if (Test-Path ".\Historico-Optimizaciones.ps1") { 
                & ".\Historico-Optimizaciones.ps1" 
            } else { Write-Host "Error: No se encuentra Historico-Optimizaciones.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '0' {
                Wait-Key
            }
        }
        '0' {
            Write-Host "Cerrando..." -ForegroundColor Gray
            Start-Sleep -Seconds 1
            exit
        }
        default {
            Write-Host "Opcion no valida." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)

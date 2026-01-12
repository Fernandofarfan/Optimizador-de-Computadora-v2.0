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

$title = "OPTIMIZADOR DE COMPUTADORA v3.0"

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
    Write-Host "  [19] 📡 MONITOR TIEMPO REAL" -ForegroundColor Cyan
    Write-Host "       (Dashboard continuo de CPU, RAM, Red, Procesos)"
    Write-Host ""
    Write-Host "  [20] ⚙️  PERFILES OPTIMIZACIÓN" -ForegroundColor Magenta
    Write-Host "       (Gaming, Trabajo, Batería, Máximo Rendimiento)"
    Write-Host ""
    Write-Host "  [21] 🎮 OPTIMIZAR JUEGOS" -ForegroundColor Green
    Write-Host "       (Detectar y optimizar juegos instalados)"
    Write-Host ""
    Write-Host "  [22] 🗂️  LIMPIAR REGISTRO" -ForegroundColor Yellow
    Write-Host "       (Limpieza segura con backup automático)"
    Write-Host ""
    Write-Host "  [23] 💿 DESFRAGMENTAR" -ForegroundColor Blue
    Write-Host "       (Inteligente: HDD defrag / SSD TRIM)"
    Write-Host ""
    Write-Host "  [24] 🔄 GESTOR UPDATES" -ForegroundColor DarkYellow
    Write-Host "       (Control completo de Windows Update)"
    Write-Host ""
    Write-Host "  [25] 🔙 PUNTOS RESTAURACIÓN" -ForegroundColor Cyan
    Write-Host "       (Crear, listar, restaurar, eliminar puntos)"
    Write-Host ""
    Write-Host "  [26] ⏰ MANTENIMIENTO AUTO" -ForegroundColor Green
    Write-Host "       (Programar limpiezas, defrag, updates automáticos)"
    Write-Host ""
    Write-Host "  [27] 📊 BENCHMARK SISTEMA" -ForegroundColor Magenta
    Write-Host "       (Pruebas CPU, RAM, Disco con comparación histórica)"
    Write-Host ""
    Write-Host "  [28] ☁️  BACKUP NUBE" -ForegroundColor Blue
    Write-Host "       (OneDrive, Google Drive, Dropbox con encriptación)"
    Write-Host ""
    Write-Host "  [29] 🖥️  DASHBOARD AVANZADO" -ForegroundColor Yellow
    Write-Host "       (Métricas 30 días, gráficos, exportar HTML/PDF)"
    Write-Host ""
    Write-Host "  [30] 🔐 PRIVACIDAD AVANZADA" -ForegroundColor Cyan
    Write-Host "       (Permisos apps, telemetría, historial, reporte)"
    Write-Host ""
    Write-Host "  [31] 📦 GESTOR APLICACIONES" -ForegroundColor Green
    Write-Host "       (Bloatware, desinstalación masiva, winget)"
    Write-Host ""
    Write-Host "  [32] 🔋 GESTOR ENERGÍA" -ForegroundColor Yellow
    Write-Host "       (Planes, batería, consumo, bloqueadores)"
    Write-Host ""    Write-Host "  [33] 📡 MONITOR DE RED" -ForegroundColor Magenta
    Write-Host "       (Tráfico, conexiones, bloqueo, test velocidad)"
    Write-Host ""
    Write-Host "  [34] 🔍 GESTOR DUPLICADOS" -ForegroundColor Yellow
    Write-Host "       (Hash MD5/SHA256, TreeSize, compresión)"
    Write-Host ""
    Write-Host "  [35] 🌐 DASHBOARD WEB" -ForegroundColor Blue
    Write-Host "       (API REST, servidor HTTP, métricas)"
    Write-Host ""
    Write-Host "  [36] 🤖 ASISTENTE IA" -ForegroundColor Green
    Write-Host "       (Diagnóstico, logs, recomendaciones)"
    Write-Host ""    Write-Host "  [0] SALIR" -ForegroundColor Gray
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
        '19' {
            if (Test-Path ".\Monitor-TiempoReal.ps1") { 
                & ".\Monitor-TiempoReal.ps1" 
            } else { Write-Host "Error: No se encuentra Monitor-TiempoReal.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '20' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Perfiles de Optimización." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Perfiles-Optimizacion.ps1") { 
                    & ".\Perfiles-Optimizacion.ps1" 
                } else { Write-Host "Error: No se encuentra Perfiles-Optimizacion.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '21' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Optimizar Juegos." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Optimizar-Juegos.ps1") { 
                    & ".\Optimizar-Juegos.ps1" 
                } else { Write-Host "Error: No se encuentra Optimizar-Juegos.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '22' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Limpiar Registro." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Limpiar-Registro.ps1") { 
                    & ".\Limpiar-Registro.ps1" 
                } else { Write-Host "Error: No se encuentra Limpiar-Registro.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '23' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Desfragmentar." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Desfragmentar-Inteligente.ps1") { 
                    & ".\Desfragmentar-Inteligente.ps1" 
                } else { Write-Host "Error: No se encuentra Desfragmentar-Inteligente.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '24' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Gestor de Updates." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Gestor-Actualizaciones.ps1") { 
                    & ".\Gestor-Actualizaciones.ps1" 
                } else { Write-Host "Error: No se encuentra Gestor-Actualizaciones.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '25' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Puntos de Restauración." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Gestor-RestorePoints.ps1") { 
                    & ".\Gestor-RestorePoints.ps1" 
                } else { Write-Host "Error: No se encuentra Gestor-RestorePoints.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '26' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Mantenimiento Automático." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Mantenimiento-Automatico.ps1") { 
                    & ".\Mantenimiento-Automatico.ps1" 
                } else { Write-Host "Error: No se encuentra Mantenimiento-Automatico.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '27' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Benchmark del Sistema." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Benchmark-Sistema.ps1") { 
                    & ".\Benchmark-Sistema.ps1" 
                } else { Write-Host "Error: No se encuentra Benchmark-Sistema.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '28' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Backup a la Nube." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Backup-Nube.ps1") { 
                    & ".\Backup-Nube.ps1" 
                } else { Write-Host "Error: No se encuentra Backup-Nube.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '29' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Dashboard Avanzado." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Dashboard-Avanzado.ps1") { 
                    & ".\Dashboard-Avanzado.ps1" 
                } else { Write-Host "Error: No se encuentra Dashboard-Avanzado.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '30' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Privacidad Avanzada." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Privacidad-Avanzada.ps1") { 
                    & ".\Privacidad-Avanzada.ps1" 
                } else { Write-Host "Error: No se encuentra Privacidad-Avanzada.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '31' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Gestor de Aplicaciones." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Gestor-Aplicaciones.ps1") { 
                    & ".\Gestor-Aplicaciones.ps1" 
                } else { Write-Host "Error: No se encuentra Gestor-Aplicaciones.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '32' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Gestor de Energía." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Gestor-Energia.ps1") { 
                    & ".\Gestor-Energia.ps1" 
                } else { Write-Host "Error: No se encuentra Gestor-Energia.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '33' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Monitor de Red." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Monitor-Red.ps1") { 
                    & ".\Monitor-Red.ps1" 
                } else { Write-Host "Error: No se encuentra Monitor-Red.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '34' {
            if (Test-Path ".\Gestor-Duplicados.ps1") { 
                & ".\Gestor-Duplicados.ps1" 
            } else { Write-Host "Error: No se encuentra Gestor-Duplicados.ps1" -ForegroundColor Red }
            Wait-Key
        }
        '35' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Dashboard Web." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Dashboard-Web.ps1") { 
                    & ".\Dashboard-Web.ps1" 
                } else { Write-Host "Error: No se encuentra Dashboard-Web.ps1" -ForegroundColor Red }
                Wait-Key
            }
        }
        '36' {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "`nError: Necesitas permisos de Administrador para Asistente IA." -ForegroundColor Red
                Wait-Key
            } else {
                if (Test-Path ".\Asistente-IA.ps1") { 
                    & ".\Asistente-IA.ps1" 
                } else { Write-Host "Error: No se encuentra Asistente-IA.ps1" -ForegroundColor Red }
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

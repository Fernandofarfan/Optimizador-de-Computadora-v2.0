# ============================================
# Instalar.ps1 - Script de Instalación Inicial
# Verifica requisitos y configura el optimizador
# Versión: 4.0.0
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INSTALACIÓN - PC OPTIMIZER SUITE v4.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Verificar Requisitos del Sistema
# ============================================

Write-Host "[1/6] Verificando versión de Windows..." -ForegroundColor Yellow

$os = Get-WmiObject Win32_OperatingSystem
$osVersion = [System.Environment]::OSVersion.Version

if ($osVersion.Major -ge 10) {
    Write-Host "  ✅ Windows 10/11 detectado" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Windows $($osVersion.Major).$($osVersion.Minor) - Puede no ser compatible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/6] Verificando versión de PowerShell..." -ForegroundColor Yellow

$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1) {
    Write-Host "  ✅ PowerShell $($psVersion.Major).$($psVersion.Minor) - Compatible" -ForegroundColor Green
} else {
    Write-Host "  ❌ PowerShell $($psVersion.Major).$($psVersion.Minor) - Requiere 5.1 o superior" -ForegroundColor Red
    Write-Host "     Descarga: https://aka.ms/wmf5download" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[3/6] Verificando permisos de ejecución..." -ForegroundColor Yellow

$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($executionPolicy -eq "Unrestricted" -or $executionPolicy -eq "RemoteSigned" -or $executionPolicy -eq "Bypass") {
    Write-Host "  ✅ Política de ejecución: $executionPolicy" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Política de ejecución: $executionPolicy" -ForegroundColor Yellow
    Write-Host "     Se recomienda cambiar a RemoteSigned" -ForegroundColor Gray
    Write-Host ""
    $response = Read-Host "¿Deseas cambiar la política de ejecución a RemoteSigned? (S/N)"
    if ($response -eq "S" -or $response -eq "s") {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "  ✅ Política actualizada correctamente" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Error al cambiar política (requiere permisos)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "[4/6] Verificando archivos del proyecto..." -ForegroundColor Yellow

$requiredFiles = @(
    "Optimizador.ps1",
    "Analizar-Sistema.ps1",
    "Optimizar-Sistema-Seguro.ps1",
    "Limpieza-Profunda.ps1",
    "Optimizar-Servicios.ps1",
    "Gestionar-Procesos.ps1",
    "Reparar-Red-Sistema.ps1",
    "Logger.ps1",
    "EJECUTAR-COMO-ADMIN.bat"
)

$missing = @()
foreach ($file in $requiredFiles) {
    if (Test-Path (Join-Path $scriptPath $file)) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file - FALTANTE" -ForegroundColor Red
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "  ⚠️  Archivos faltantes detectados. Recomendado descargar versión completa." -ForegroundColor Yellow
    Write-Host "     https://github.com/Fernandofarfan/Optimizador-de-Computadora/releases" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[5/6] Verificando espacio en disco..." -ForegroundColor Yellow

$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)

if ($freeSpaceGB -gt 1) {
    Write-Host "  ✅ Espacio libre en C: $freeSpaceGB GB" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Espacio libre muy bajo: $freeSpaceGB GB" -ForegroundColor Yellow
    Write-Host "     Se recomienda liberar espacio antes de continuar" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[6/6] Configuración de directorios..." -ForegroundColor Yellow

# Crear carpeta de logs si no existe
$logsPath = Join-Path $scriptPath "logs"
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    Write-Host "  ✅ Carpeta de logs creada: logs/" -ForegroundColor Green
} else {
    Write-Host "  ✅ Carpeta de logs existente" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INSTALACIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Resumen y Próximos Pasos
# ============================================

Write-Host "📊 RESUMEN DEL SISTEMA:" -ForegroundColor Yellow
Write-Host "  - SO: $($os.Caption)" -ForegroundColor White
Write-Host "  - PowerShell: $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor White
Write-Host "  - Espacio libre: $freeSpaceGB GB" -ForegroundColor White
Write-Host "  - Arquitectura: $($os.OSArchitecture)" -ForegroundColor White
Write-Host ""

Write-Host "🚀 PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host "  1. Haz doble clic en: EJECUTAR-COMO-ADMIN.bat" -ForegroundColor White
Write-Host "  2. Selecciona opción [1] para analizar tu sistema" -ForegroundColor White
Write-Host "  3. Revisa las recomendaciones" -ForegroundColor White
Write-Host "  4. Ejecuta las optimizaciones necesarias" -ForegroundColor White
Write-Host ""

Write-Host "📚 DOCUMENTACIÓN:" -ForegroundColor Yellow
Write-Host "  - README.md - Guía completa de uso" -ForegroundColor White
Write-Host "  - CONTRIBUTING.md - Cómo contribuir" -ForegroundColor White
Write-Host "  - Ejemplo-Logger.ps1 - Ejemplos de logging" -ForegroundColor White
Write-Host "  - Web: https://fernandofarfan.github.io/Optimizador-de-Computadora/" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "  - Crea un punto de restauración antes de optimizaciones profundas" -ForegroundColor White
Write-Host "  - Usa permisos de administrador para funciones avanzadas" -ForegroundColor White
Write-Host "  - Lee las advertencias antes de confirmar cambios" -ForegroundColor White
Write-Host ""

$response = Read-Host "¿Deseas ejecutar el optimizador ahora? (S/N)"
if ($response -eq "S" -or $response -eq "s") {
    Write-Host ""
    Write-Host "Iniciando optimizador..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    & "$scriptPath\Optimizador.ps1"
} else {
    Write-Host ""
    Write-Host "Instalación completa. Ejecuta EJECUTAR-COMO-ADMIN.bat cuando estés listo." -ForegroundColor Green
    Write-Host ""
    Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
    Read-Host
}

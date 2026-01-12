@echo off
::==============================================================================
:: OPTIMIZADOR DE COMPUTADORA v4.0.0
:: Lanzador de PowerShell con Permisos de Administrador
::==============================================================================
:: Descripción: Este archivo inicia el Optimizador de PC con los permisos 
::             necesarios (Administrador) para realizar optimizaciones.
::
:: Requisitos:  - Windows 10/11
::             - PowerShell 5.1+
::             - Permisos de Administrador
::
:: Uso:        1. Haz clic doble en este archivo
::             2. Acepta el aviso de Control de Cuentas de Usuario (UAC)
::             3. Se abrirá PowerShell con el menú principal
::
:: Versión:    4.0.0
:: Fecha:      12/01/2026
::==============================================================================

setlocal enabledelayedexpansion

:: Verificar si se ejecuta con permisos de administrador
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo.
    echo [!] Este script requiere permisos de Administrador
    echo [!] Solicitando elevación de permisos...
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process CMD -Verb RunAs -ArgumentList '/c %0'"
    exit /b
)

:: Forzar ruta actual a la carpeta donde esta este archivo
cd /d "%~dp0"

cls
echo.
echo ================================================================================
echo                   OPTIMIZADOR DE COMPUTADORA v4.0.0
echo ================================================================================
echo.
echo [+] Iniciando PowerShell con permisos de Administrador...
echo [+] Cargando Optimizador.ps1...
echo.

:: Lanzar PowerShell como Admin con el script principal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimizador.ps1"

exit /b

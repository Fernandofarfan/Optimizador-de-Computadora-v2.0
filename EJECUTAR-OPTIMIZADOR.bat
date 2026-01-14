@echo off
::==============================================================================
:: OPTIMIZADOR DE COMPUTADORA v4.0.0 - LAUNCHER UNIFICADO
::==============================================================================
:: Descripción: Lanzador único con menú de opciones para ejecutar el optimizador
::              en diferentes modos: Consola, GUI o Administrador.
::
:: Requisitos:  - Windows 10/11
::              - PowerShell 5.1+
::
:: Uso:         1. Doble clic en este archivo
::              2. Selecciona el modo de ejecución
::              3. Acepta permisos de administrador si es necesario
::
:: Versión:     4.0.0
:: Fecha:       13/01/2026
::==============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

:MENU
cls
echo.
echo ================================================================================
echo                   OPTIMIZADOR DE COMPUTADORA v4.0.0
echo                         LANZADOR UNIFICADO
echo ================================================================================
echo.
echo   Selecciona el modo de ejecucion:
echo.
echo   [1] Modo Consola Tradicional (Read-Host)
echo   [2] Modo Interfaz Grafica (Out-GridView)
echo   [3] Ejecutar como Administrador (RECOMENDADO)
echo   [4] Ejecutar GUI como Administrador
echo.
echo   [0] Salir
echo.
echo ================================================================================
echo.

set /p OPCION="  Ingrese numero (1-4, 0=Salir): "

if "%OPCION%"=="1" goto CONSOLA
if "%OPCION%"=="2" goto GUI
if "%OPCION%"=="3" goto ADMIN
if "%OPCION%"=="4" goto GUI_ADMIN
if "%OPCION%"=="0" goto SALIR

echo.
echo [!] Opcion invalida. Intente nuevamente.
timeout /t 2 /nobreak >nul
goto MENU

:CONSOLA
cls
echo.
echo [+] Modo CONSOLA: Iniciando PowerShell con menu tradicional...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimizador.ps1"
goto FIN

:GUI
cls
echo.
echo [+] Modo GUI: Iniciando PowerShell con Out-GridView...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$useGUI=$true; & '%~dp0Optimizador.ps1'"
goto FIN

:ADMIN
:: Verificar si ya somos admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo.
    echo [!] Solicitando permisos de Administrador...
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File \"%~dp0Optimizador.ps1\"'"
    goto SALIR
) else (
    cls
    echo.
    echo [+] Ya tienes permisos de Administrador
    echo [+] Iniciando Optimizador en modo CONSOLA ADMIN...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimizador.ps1"
    goto FIN
)

:GUI_ADMIN
:: Verificar si ya somos admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo.
    echo [!] Solicitando permisos de Administrador para GUI...
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -Command \"$useGUI=$true; & \\\"%~dp0Optimizador.ps1\\\"\"'"
    goto SALIR
) else (
    cls
    echo.
    echo [+] Ya tienes permisos de Administrador
    echo [+] Iniciando Optimizador en modo GUI ADMIN...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$useGUI=$true; & '%~dp0Optimizador.ps1'"
    goto FIN
)

:FIN
echo.
echo ================================================================================
echo [+] Optimizador finalizado
echo.
pause
goto MENU

:SALIR
echo.
echo [+] Saliendo...
timeout /t 1 /nobreak >nul
exit /b 0

@echo off
title Optimizador de PC - Iniciador
color 0A
setlocal enabledelayedexpansion
cd /d "%~dp0"

cls
echo.
echo ================================================================================
echo                      OPTIMIZADOR DE PC - PROFESIONAL
echo                           Version 2.0 - 2026
echo ================================================================================
echo.
echo  Verificando permisos de administrador...
echo.

REM Verificar si somos admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo  [!] Se requieren permisos de Administrador
    echo  [i] Solicitando elevacion de privilegios...
    echo.
    timeout /t 2 /nobreak >nul
    
    REM Crear un batch temporal que levante privilegios
    (
        echo @echo off
        echo title Optimizador de PC
        echo color 0B
        echo cd /d "%~dp0"
        echo powershell -NoExit -NoProfile -ExecutionPolicy Bypass -File "Optimizador.ps1"
    ) > "%TEMP%\ElevateOptimizador.bat"
    
    REM Ejecutar el batch con elevación de privilegios
    powershell -Command "Start-Process '%TEMP%\ElevateOptimizador.bat' -Verb RunAs"
    
    REM Esperar y limpiar
    timeout /t 2 /nobreak >nul
    if exist "%TEMP%\ElevateOptimizador.bat" del /q "%TEMP%\ElevateOptimizador.bat"
    
    exit /b 0
) else (
    echo  [OK] Permisos de Administrador confirmados
    echo  [OK] Iniciando Optimizador de PC...
    echo.
    timeout /t 1 /nobreak >nul
    color 0B
    powershell -NoExit -NoProfile -ExecutionPolicy Bypass -File "Optimizador.ps1"
    exit /b 0
)

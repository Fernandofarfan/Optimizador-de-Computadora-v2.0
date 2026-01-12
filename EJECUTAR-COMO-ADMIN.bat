@echo off
:: Forzar ruta actual a la carpeta donde esta este archivo
cd /d "%~dp0"

:: Lanzar PowerShell como Admin usando la ruta absoluta del script
powershell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File ""%~dp0Optimizador.ps1""'"
exit

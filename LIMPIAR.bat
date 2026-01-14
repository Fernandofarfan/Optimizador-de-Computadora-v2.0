@echo off
REM Script simple para eliminar duplicados
cd /d "c:\Users\ROCVIK\OneDrive\Escritorio\Proyectos\Optimizador de Computadora"

REM Eliminar sin verificación
del *-NEW.ps1 /F /Q 2>nul
del *-OLD.ps1 /F /Q 2>nul
del *BACKUP*.ps1 /F /Q 2>nul
del *CORRUPTO*.ps1 /F /Q 2>nul

echo Completado!
timeout /t 3 /nobreak

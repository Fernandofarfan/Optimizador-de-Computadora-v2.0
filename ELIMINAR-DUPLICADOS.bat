@echo off
setlocal enabledelayedexpansion
color 0A
title ELIMINAR DUPLICADOS - Optimizador PC

cd /d "c:\Users\ROCVIK\OneDrive\Escritorio\Proyectos\Optimizador de Computadora"

echo.
echo =======================================
echo   ELIMINANDO DUPLICADOS
echo =======================================
echo.

set contador=0

echo Eliminando archivos -NEW...
for %%f in (*-NEW.ps1) do (
    del /F /Q "%%f" 2>nul
    if not exist "%%f" (
        echo   + Eliminado: %%f
        set /a contador=!contador!+1
    )
)

echo Eliminando archivos -OLD...
for %%f in (*-OLD.ps1) do (
    del /F /Q "%%f" 2>nul
    if not exist "%%f" (
        echo   + Eliminado: %%f
        set /a contador=!contador!+1
    )
)

echo Eliminando archivos BACKUP...
for %%f in (*BACKUP*.ps1) do (
    del /F /Q "%%f" 2>nul
    if not exist "%%f" (
        echo   + Eliminado: %%f
        set /a contador=!contador!+1
    )
)

echo Eliminando archivos CORRUPTO...
for %%f in (*CORRUPTO*.ps1) do (
    del /F /Q "%%f" 2>nul
    if not exist "%%f" (
        echo   + Eliminado: %%f
        set /a contador=!contador!+1
    )
)

echo.
echo =======================================
echo   TOTAL ELIMINADOS: %contador%
echo =======================================
echo.

echo Verificando...
setlocal disabledelayedexpansion
dir *-NEW.ps1 /b 2>nul >nul && (echo - Aun hay archivos -NEW) || (echo OK - Sin -NEW)
dir *-OLD.ps1 /b 2>nul >nul && (echo - Aun hay archivos -OLD) || (echo OK - Sin -OLD)
dir *BACKUP*.ps1 /b 2>nul >nul && (echo - Aun hay archivos BACKUP) || (echo OK - Sin BACKUP)
dir *CORRUPTO*.ps1 /b 2>nul >nul && (echo - Aun hay archivos CORRUPTO) || (echo OK - Sin CORRUPTO)

echo.
pause

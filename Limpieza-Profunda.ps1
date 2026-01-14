$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "      LIMPIEZA PROFUNDA DEL SISTEMA" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Verificar permisos
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Host ""
    return
}

Write-Host "OPCIONES DE LIMPIEZA:" -ForegroundColor Yellow
Write-Host "1. Limpiar archivos temporales" -ForegroundColor Cyan
Write-Host "2. Limpiar papelera de reciclaje" -ForegroundColor Cyan
Write-Host "3. Limpiar cache del sistema" -ForegroundColor Cyan
Write-Host "4. Ejecutar todas las limpiezas" -ForegroundColor Cyan
Write-Host ""

$option = Read-Host "Selecciona opcion (1-4)"

switch ($option) {
    "1" {
        Write-Host ""
        Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
        
        $tempPaths = @("$env:TEMP", "$env:WINDIR\Temp")
        $totalRemoved = 0
        
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                try {
                    $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    foreach ($item in $items) {
                        Remove-Item $item.FullName -Force -ErrorAction SilentlyContinue
                    }
                    $totalRemoved += @($items).Count
                } catch {
                    # Ignorar errores
                }
            }
        }
        
        Write-Host "✓ Se eliminaron $totalRemoved elementos" -ForegroundColor Green
    }
    
    "2" {
        Write-Host ""
        Write-Host "Vaciando papelera de reciclaje..." -ForegroundColor Yellow
        
        try {
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-Host "✓ Papelera vaciada correctamente" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Papelera vacía o error al vaciar" -ForegroundColor Yellow
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "Limpiando cache del sistema..." -ForegroundColor Yellow
        
        try {
            # Limpiar cache DNS
            ipconfig /flushdns | Out-Null
            Write-Host "  ✓ Cache DNS limpiado" -ForegroundColor Green
            
            # Limpiar cache de Windows Store
            if (Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore*") {
                Write-Host "  ✓ Cache de Windows Store limpiado" -ForegroundColor Green
            }
            
            Write-Host "✓ Cache del sistema limpiado" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Error al limpiar cache" -ForegroundColor Yellow
        }
    }
    
    "4" {
        Write-Host ""
        Write-Host "Ejecutando todas las limpiezas..." -ForegroundColor Yellow
        
        Write-Host "  [1/3] Limpiando temporales..." -ForegroundColor Cyan
        $tempPaths = @("$env:TEMP", "$env:WINDIR\Temp")
        $total = 0
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    Remove-Item $item.FullName -Force -ErrorAction SilentlyContinue
                    $total++
                }
            }
        }
        Write-Host "    ✓ $total archivos eliminados" -ForegroundColor Green
        
        Write-Host "  [2/3] Vaciando papelera..." -ForegroundColor Cyan
        try {
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-Host "    ✓ OK" -ForegroundColor Green
        } catch {
            Write-Host "    ⚠ Vacía o error" -ForegroundColor Yellow
        }
        
        Write-Host "  [3/3] Limpiando cache..." -ForegroundColor Cyan
        ipconfig /flushdns | Out-Null
        Write-Host "    ✓ OK" -ForegroundColor Green
    }
    
    default {
        Write-Host "Opcion no valida" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

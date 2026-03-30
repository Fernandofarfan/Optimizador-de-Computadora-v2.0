$ErrorActionPreference = "Continue"
Write-Host "HISTORIAL DE OPERACIONES" -ForegroundColor Green
Write-Host ""

$logPath = "$PSScriptRoot\optimizador_historial.log"

function Show-History {
    if (Test-Path $logPath) {
        Write-Host "Mostrando historial de operaciones:" -ForegroundColor Cyan
        Write-Host "====================================================" -ForegroundColor Gray
        $content = Get-Content $logPath -ErrorAction SilentlyContinue
        if ($content) {
            $content | Select-Object -Last 50 | ForEach-Object {
                Write-Host $_ -ForegroundColor White
            }
        } else {
            Write-Host "El historial esta vacio" -ForegroundColor Yellow
        }
        Write-Host "====================================================" -ForegroundColor Gray
    } else {
        Write-Host "No existe historial de operaciones" -ForegroundColor Yellow
        Write-Host "El historial se creara automaticamente cuando ejecutes operaciones" -ForegroundColor Gray
    }
}

function Add-LogEntry {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
    Write-Host "Entrada agregada al historial" -ForegroundColor Green
}

function Clear-History {
    if (Test-Path $logPath) {
        Remove-Item $logPath -Force
        Write-Host "Historial eliminado correctamente" -ForegroundColor Green
    } else {
        Write-Host "No hay historial para eliminar" -ForegroundColor Yellow
    }
}

Write-Host "[1] Ver historial de operaciones" -ForegroundColor Cyan
Write-Host "[2] Agregar entrada manual al historial" -ForegroundColor Cyan
Write-Host "[3] Limpiar historial" -ForegroundColor Cyan
Write-Host "[0] Salir" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona una opcion"

Write-Host ""
switch ($opcion) {
    "1" {
        Show-History
    }
    "2" {
        $mensaje = Read-Host "Ingresa el mensaje para el historial"
        if ($mensaje) {
            Add-LogEntry -Message $mensaje
        }
    }
    "3" {
        $confirmar = Read-Host "Estas seguro de eliminar el historial? (S/N)"
        if ($confirmar -eq "S" -or $confirmar -eq "s") {
            Clear-History
        } else {
            Write-Host "Operacion cancelada" -ForegroundColor Gray
        }
    }
    "0" {
        Write-Host "Saliendo..." -ForegroundColor Gray
    }
    default {
        Write-Host "Opcion invalida" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Presiona ENTER para salir"

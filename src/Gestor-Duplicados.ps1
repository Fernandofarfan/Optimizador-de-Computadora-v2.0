$ErrorActionPreference = "Continue"
Write-Host "GESTOR DE ARCHIVOS DUPLICADOS" -ForegroundColor Green
Write-Host ""
Write-Host "[1] Buscar duplicados en una carpeta" -ForegroundColor Cyan
Write-Host "[2] Buscar duplicados en Descargas" -ForegroundColor Cyan
Write-Host "[3] Buscar duplicados en Documentos" -ForegroundColor Cyan
Write-Host "[4] Buscar duplicados en Escritorio" -ForegroundColor Cyan
Write-Host "[0] Salir" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona una opcion"

function Find-Duplicates {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "La ruta no existe: $Path" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "Buscando archivos en: $Path" -ForegroundColor Yellow
    
    try {
        $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
        $totalFiles = $files.Count
        Write-Host "Total de archivos encontrados: $totalFiles" -ForegroundColor Cyan
        
        if ($totalFiles -eq 0) {
            Write-Host "No se encontraron archivos" -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host "Calculando hashes..." -ForegroundColor Yellow
        $hashTable = @{}
        $processed = 0
        
        foreach ($file in $files) {
            $processed++
            if ($processed -eq 100 -or $processed -eq $totalFiles) {
                $percent = [math]::Round(($processed / $totalFiles) * 100, 1)
                Write-Host "Progreso: $processed / $totalFiles archivos ($percent porciento)" -ForegroundColor Gray
            }
            
            try {
                $hash = (Get-FileHash -Path $file.FullName -Algorithm MD5 -ErrorAction Stop).Hash
                
                if (-not $hashTable.ContainsKey($hash)) {
                    $hashTable[$hash] = @()
                }
                
                $hashTable[$hash] += $file
            }
            catch {
                # Ignorar archivos que no se pueden leer
            }
        }
        
        Write-Host ""
        Write-Host "Analizando duplicados..." -ForegroundColor Yellow
        
        $duplicateGroups = $hashTable.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        $duplicateCount = 0
        $wastedSpace = 0
        
        if ($duplicateGroups.Count -eq 0) {
            Write-Host "No se encontraron archivos duplicados" -ForegroundColor Green
            return
        }
        
        Write-Host ""
        Write-Host "Archivos duplicados encontrados:" -ForegroundColor Cyan
        Write-Host ""
        
        $groupNum = 0
        foreach ($group in $duplicateGroups) {
            $groupNum++
            if ($groupNum -gt 20) {
                Write-Host "... y mas duplicados (mostrando solo los primeros 20 grupos)" -ForegroundColor Gray
                break
            }
            
            $files = $group.Value
            $fileSize = [math]::Round($files[0].Length / 1MB, 2)
            $dupes = $files.Count - 1
            $wastedMB = [math]::Round(($files[0].Length * $dupes) / 1MB, 2)
            
            Write-Host "Grupo $groupNum - Archivo: $($files[0].Name)" -ForegroundColor Yellow
            Write-Host "  Tamano: $fileSize MB" -ForegroundColor White
            Write-Host "  Copias duplicadas: $dupes" -ForegroundColor Red
            Write-Host "  Espacio desperdiciado: $wastedMB MB" -ForegroundColor Red
            
            foreach ($file in $files) {
                Write-Host "    -> $($file.FullName)" -ForegroundColor Gray
            }
            
            Write-Host ""
            $duplicateCount += $dupes
            $wastedSpace += ($files[0].Length * $dupes)
        }
        
        $wastedMB = [math]::Round($wastedSpace / 1MB, 2)
        $wastedGB = [math]::Round($wastedSpace / 1GB, 2)
        
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "RESUMEN" -ForegroundColor White
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "Archivos duplicados: $duplicateCount" -ForegroundColor Yellow
        Write-Host "Grupos de duplicados: $($duplicateGroups.Count)" -ForegroundColor Yellow
        Write-Host "Espacio desperdiciado: $wastedMB MB ($wastedGB GB)" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

switch ($opcion) {
    "1" {
        $ruta = Read-Host "Ingresa la ruta completa de la carpeta"
        Find-Duplicates -Path $ruta
    }
    "2" {
        Find-Duplicates -Path "$env:USERPROFILE\Downloads"
    }
    "3" {
        Find-Duplicates -Path "$env:USERPROFILE\Documents"
    }
    "4" {
        $desktop = [Environment]::GetFolderPath("Desktop")
        Find-Duplicates -Path $desktop
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

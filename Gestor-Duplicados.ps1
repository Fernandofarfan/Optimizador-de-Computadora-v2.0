<#
.SYNOPSIS
    Gestor Inteligente de Archivos Duplicados
.DESCRIPTION
    Busca archivos duplicados por hash MD5/SHA256, genera visualización TreeSize,
    permite eliminar duplicados de forma segura y crear archivo comprimido.
.NOTES
    Versión: 3.0.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11
#>

#Requires -Version 5.1

$Global:DuplicatesLogPath = "$env:USERPROFILE\OptimizadorPC-Duplicates.json"
$Global:DuplicatesScriptVersion = "3.0.0"
$Global:ScanResults = @()

# Importar Logger si existe
if (Test-Path ".\Logger.ps1") {
    . ".\Logger.ps1"
    $Global:UseLogger = $true
} else {
    $Global:UseLogger = $false
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║                                                              ║" -ForegroundColor Magenta
    Write-Host "  ║       🔍 GESTOR INTELIGENTE DE DUPLICADOS                   ║" -ForegroundColor White
    Write-Host "  ║                  Versión $Global:DuplicatesScriptVersion                      ║" -ForegroundColor Magenta
    Write-Host "  ║                                                              ║" -ForegroundColor Magenta
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Get-DuplicateFiles {
    <#
    .SYNOPSIS
        Busca archivos duplicados en un directorio usando hash
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [ValidateSet("MD5", "SHA256")]
        [string]$Algorithm = "MD5",
        
        [string[]]$Extensions = @("*"),
        
        [int64]$MinSizeBytes = 0,
        
        [switch]$Recursive
    )
    
    Write-Host "`n[*] Iniciando búsqueda de duplicados..." -ForegroundColor Cyan
    Write-Host "    Ruta: $Path" -ForegroundColor Gray
    Write-Host "    Algoritmo: $Algorithm" -ForegroundColor Gray
    Write-Host "    Recursivo: $Recursive" -ForegroundColor Gray
    Write-Log "Iniciando escaneo de duplicados en: $Path" "INFO"
    
    if (-not (Test-Path $Path)) {
        Write-Host "  [✗] La ruta especificada no existe" -ForegroundColor Red
        Write-Log "Ruta no existe: $Path" "ERROR"
        return $null
    }
    
    # Obtener todos los archivos
    Write-Host "`n[1/4] Enumerando archivos..." -ForegroundColor Yellow
    
    $getItemParams = @{
        Path = $Path
        File = $true
        ErrorAction = "SilentlyContinue"
    }
    
    if ($Recursive) {
        $getItemParams.Recurse = $true
    }
    
    $allFiles = Get-ChildItem @getItemParams | Where-Object { 
        $_.Length -ge $MinSizeBytes -and 
        ($Extensions -contains "*" -or $Extensions -contains $_.Extension)
    }
    
    $totalFiles = $allFiles.Count
    Write-Host "  [✓] $totalFiles archivo(s) encontrado(s)" -ForegroundColor Green
    
    if ($totalFiles -eq 0) {
        Write-Host "  [i] No hay archivos para analizar" -ForegroundColor Yellow
        return $null
    }
    
    # Calcular hashes
    Write-Host "`n[2/4] Calculando hashes ($Algorithm)..." -ForegroundColor Yellow
    
    $fileHashes = @{}
    $processed = 0
    $startTime = Get-Date
    
    foreach ($file in $allFiles) {
        $processed++
        
        if ($processed % 10 -eq 0 -or $processed -eq $totalFiles) {
            $percent = [math]::Round(($processed / $totalFiles) * 100, 1)
            $elapsed = ((Get-Date) - $startTime).TotalSeconds
            $rate = if ($elapsed -gt 0) { [math]::Round($processed / $elapsed, 1) } else { 0 }
            
            Write-Progress -Activity "Calculando hashes" `
                -Status "$processed de $totalFiles archivos ($percent%) - $rate archivos/seg" `
                -PercentComplete $percent
        }
        
        try {
            $hash = (Get-FileHash -Path $file.FullName -Algorithm $Algorithm -ErrorAction Stop).Hash
            
            if (-not $fileHashes.ContainsKey($hash)) {
                $fileHashes[$hash] = @()
            }
            
            $fileHashes[$hash] += [PSCustomObject]@{
                FullName = $file.FullName
                Name = $file.Name
                SizeBytes = $file.Length
                SizeMB = [math]::Round($file.Length / 1MB, 2)
                LastWriteTime = $file.LastWriteTime
                Extension = $file.Extension
                Directory = $file.DirectoryName
            }
        }
        catch {
            Write-Log "Error calculando hash de $($file.FullName): $_" "WARNING"
        }
    }
    
    Write-Progress -Activity "Calculando hashes" -Completed
    Write-Host "  [✓] Hashes calculados correctamente" -ForegroundColor Green
    
    # Identificar duplicados
    Write-Host "`n[3/4] Identificando duplicados..." -ForegroundColor Yellow
    
    $duplicateGroups = $fileHashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    $duplicateCount = ($duplicateGroups | Measure-Object -Property { $_.Value.Count - 1 } -Sum).Sum
    
    if ($duplicateCount -eq 0) {
        Write-Host "  [✓] No se encontraron archivos duplicados" -ForegroundColor Green
        Write-Log "No se encontraron duplicados en: $Path" "INFO"
        return $null
    }
    
    Write-Host "  [✓] $duplicateCount archivo(s) duplicado(s) encontrado(s)" -ForegroundColor Green
    
    # Calcular espacio desperdiciado
    Write-Host "`n[4/4] Calculando espacio desperdiciado..." -ForegroundColor Yellow
    
    $wastedSpace = 0
    foreach ($group in $duplicateGroups) {
        $files = $group.Value
        $fileSize = $files[0].SizeBytes
        $duplicates = $files.Count - 1
        $wastedSpace += ($fileSize * $duplicates)
    }
    
    $wastedSpaceMB = [math]::Round($wastedSpace / 1MB, 2)
    $wastedSpaceGB = [math]::Round($wastedSpace / 1GB, 2)
    
    Write-Host "  [✓] Espacio desperdiciado: $wastedSpaceMB MB ($wastedSpaceGB GB)" -ForegroundColor Red
    Write-Log "Duplicados encontrados: $duplicateCount archivos, $wastedSpaceGB GB desperdiciados" "INFO"
    
    # Guardar resultados globales
    $Global:ScanResults = $duplicateGroups
    
    # Retornar resumen
    return [PSCustomObject]@{
        TotalFiles = $totalFiles
        DuplicateFiles = $duplicateCount
        DuplicateGroups = $duplicateGroups.Count
        WastedSpaceBytes = $wastedSpace
        WastedSpaceMB = $wastedSpaceMB
        WastedSpaceGB = $wastedSpaceGB
        Algorithm = $Algorithm
        ScanPath = $Path
        ScanDate = Get-Date
        Groups = $duplicateGroups
    }
}

function Show-DuplicateGroups {
    <#
    .SYNOPSIS
        Muestra grupos de duplicados de forma organizada
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ScanResult,
        
        [int]$MaxGroups = 20
    )
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              GRUPOS DE ARCHIVOS DUPLICADOS                           ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $groups = $ScanResult.Groups | Sort-Object { $_.Value[0].SizeBytes * ($_.Value.Count - 1) } -Descending
    $displayedGroups = $groups | Select-Object -First $MaxGroups
    $groupNumber = 0
    
    foreach ($group in $displayedGroups) {
        $groupNumber++
        $files = $group.Value
        $originalSize = $files[0].SizeMB
        $duplicateCount = $files.Count - 1
        $wastedSpace = $originalSize * $duplicateCount
        
        Write-Host "  [$groupNumber] 📄 $($files[0].Name)" -ForegroundColor Yellow
        Write-Host "      Tamaño: $originalSize MB" -ForegroundColor Gray
        Write-Host "      Duplicados: $duplicateCount copia(s)" -ForegroundColor Red
        Write-Host "      Espacio desperdiciado: $wastedSpace MB" -ForegroundColor Red
        Write-Host ""
        
        foreach ($file in $files) {
            $isOriginal = if ($file -eq $files[0]) { "🟢 Original" } else { "🔴 Duplicado" }
            Write-Host "      $isOriginal - $($file.FullName)" -ForegroundColor DarkGray
        }
        
        Write-Host ""
    }
    
    if ($groups.Count -gt $MaxGroups) {
        Write-Host "  [i] Mostrando $MaxGroups de $($groups.Count) grupos" -ForegroundColor Yellow
        Write-Host "      Use la exportación HTML para ver todos los detalles" -ForegroundColor Gray
        Write-Host ""
    }
}

function Remove-DuplicateFiles {
    <#
    .SYNOPSIS
        Elimina archivos duplicados manteniendo el original
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ScanResult,
        
        [ValidateSet("KeepFirst", "KeepNewest", "KeepOldest")]
        [string]$KeepStrategy = "KeepFirst",
        
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Eliminando duplicados (Estrategia: $KeepStrategy)..." -ForegroundColor Cyan
    
    if ($WhatIf) {
        Write-Host "  [i] Modo simulación activado (no se eliminarán archivos)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    $confirmation = Read-Host "¿Está seguro de eliminar los duplicados? (S/N)"
    
    if ($confirmation -ne "S" -and $confirmation -ne "s") {
        Write-Host "  [i] Operación cancelada" -ForegroundColor Yellow
        return
    }
    
    $deletedCount = 0
    $freedSpace = 0
    $errors = 0
    
    foreach ($group in $ScanResult.Groups) {
        $files = $group.Value
        
        # Determinar qué archivo mantener
        $fileToKeep = switch ($KeepStrategy) {
            "KeepFirst" { $files[0] }
            "KeepNewest" { $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }
            "KeepOldest" { $files | Sort-Object LastWriteTime | Select-Object -First 1 }
        }
        
        # Eliminar los demás
        foreach ($file in $files) {
            if ($file.FullName -eq $fileToKeep.FullName) {
                continue
            }
            
            try {
                if (-not $WhatIf) {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                }
                
                Write-Host "  [✓] Eliminado: $($file.FullName)" -ForegroundColor Green
                $deletedCount++
                $freedSpace += $file.SizeBytes
                Write-Log "Duplicado eliminado: $($file.FullName)" "INFO"
            }
            catch {
                Write-Host "  [✗] Error al eliminar: $($file.FullName)" -ForegroundColor Red
                Write-Log "Error eliminando duplicado: $($file.FullName) - $_" "ERROR"
                $errors++
            }
        }
    }
    
    $freedSpaceMB = [math]::Round($freedSpace / 1MB, 2)
    $freedSpaceGB = [math]::Round($freedSpace / 1GB, 2)
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          RESUMEN DE ELIMINACIÓN                    ║" -ForegroundColor White
    Write-Host "╠════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║  Archivos eliminados: $deletedCount".PadRight(53) + "║" -ForegroundColor Cyan
    Write-Host "║  Espacio liberado: $freedSpaceMB MB ($freedSpaceGB GB)".PadRight(53) + "║" -ForegroundColor Green
    Write-Host "║  Errores: $errors".PadRight(53) + "║" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Log "Eliminación completada: $deletedCount archivos, $freedSpaceGB GB liberados, $errors errores" "SUCCESS"
}

function Export-DuplicatesReport {
    <#
    .SYNOPSIS
        Exporta reporte de duplicados en formato HTML con visualización TreeSize
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ScanResult
    )
    
    Write-Host "`n[*] Generando reporte HTML..." -ForegroundColor Cyan
    
    $reportPath = "$env:USERPROFILE\OptimizadorPC-Duplicados-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    # Generar HTML
    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Archivos Duplicados</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8f9fa;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s;
        }
        .stat-card:hover {
            transform: translateY(-5px);
        }
        .stat-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
            margin: 10px 0;
        }
        .stat-label {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .groups {
            padding: 40px;
        }
        .group {
            background: #f8f9fa;
            border-left: 5px solid #667eea;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 8px;
        }
        .group-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .group-title {
            font-size: 1.3em;
            color: #333;
            font-weight: 600;
        }
        .group-meta {
            display: flex;
            gap: 20px;
            font-size: 0.9em;
            color: #666;
        }
        .badge {
            background: #667eea;
            color: white;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
        }
        .badge.danger {
            background: #e74c3c;
        }
        .files-list {
            margin-top: 15px;
        }
        .file-item {
            background: white;
            padding: 12px 15px;
            margin: 8px 0;
            border-radius: 5px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-left: 3px solid transparent;
        }
        .file-item.original {
            border-left-color: #2ecc71;
        }
        .file-item.duplicate {
            border-left-color: #e74c3c;
        }
        .file-path {
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            color: #555;
            flex: 1;
        }
        .file-tag {
            padding: 3px 10px;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: 600;
        }
        .file-tag.original {
            background: #d4edda;
            color: #155724;
        }
        .file-tag.duplicate {
            background: #f8d7da;
            color: #721c24;
        }
        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 20px;
            font-size: 0.9em;
        }
        .chart-container {
            padding: 40px;
            background: white;
        }
        .bar {
            display: flex;
            align-items: center;
            margin: 10px 0;
        }
        .bar-label {
            min-width: 150px;
            font-weight: 600;
        }
        .bar-visual {
            flex: 1;
            background: #e0e0e0;
            height: 30px;
            border-radius: 5px;
            overflow: hidden;
            position: relative;
        }
        .bar-fill {
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            height: 100%;
            transition: width 1s;
        }
        .bar-value {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            color: white;
            font-weight: bold;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Reporte de Archivos Duplicados</h1>
            <p>Optimizador de Computadora v$Global:DuplicatesScriptVersion</p>
            <p>Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-label">Total Archivos</div>
                <div class="stat-value">$($ScanResult.TotalFiles)</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Duplicados</div>
                <div class="stat-value">$($ScanResult.DuplicateFiles)</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Grupos</div>
                <div class="stat-value">$($ScanResult.DuplicateGroups)</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Espacio Desperdiciado</div>
                <div class="stat-value">$($ScanResult.WastedSpaceGB) GB</div>
            </div>
        </div>
        
        <div class="chart-container">
            <h2 style="margin-bottom: 20px;">📊 Top 10 Grupos por Espacio Desperdiciado</h2>
"@
    
    # Top 10 grupos por tamaño
    $topGroups = $ScanResult.Groups | Sort-Object { $_.Value[0].SizeBytes * ($_.Value.Count - 1) } -Descending | Select-Object -First 10
    $maxWasted = ($topGroups[0].Value[0].SizeBytes * ($topGroups[0].Value.Count - 1))
    
    foreach ($group in $topGroups) {
        $files = $group.Value
        $wastedBytes = $files[0].SizeBytes * ($files.Count - 1)
        $wastedMB = [math]::Round($wastedBytes / 1MB, 2)
        $percentage = [math]::Round(($wastedBytes / $maxWasted) * 100, 1)
        
        $html += @"
            <div class="bar">
                <div class="bar-label">$($files[0].Name)</div>
                <div class="bar-visual">
                    <div class="bar-fill" style="width: $percentage%"></div>
                    <div class="bar-value">$wastedMB MB</div>
                </div>
            </div>
"@
    }
    
    $html += @"
        </div>
        
        <div class="groups">
            <h2 style="margin-bottom: 30px;">📁 Grupos de Duplicados</h2>
"@
    
    $groupNumber = 0
    foreach ($group in $ScanResult.Groups) {
        $groupNumber++
        $files = $group.Value
        $duplicateCount = $files.Count - 1
        $wastedMB = [math]::Round($files[0].SizeBytes * $duplicateCount / 1MB, 2)
        
        $html += @"
            <div class="group">
                <div class="group-header">
                    <div class="group-title">$($files[0].Name)</div>
                    <div class="group-meta">
                        <span class="badge">$($files[0].SizeMB) MB</span>
                        <span class="badge danger">$duplicateCount duplicado(s)</span>
                        <span class="badge danger">$wastedMB MB desperdiciados</span>
                    </div>
                </div>
                <div class="files-list">
"@
        
        $isFirst = $true
        foreach ($file in $files) {
            $tag = if ($isFirst) { "original" } else { "duplicate" }
            $tagText = if ($isFirst) { "ORIGINAL" } else { "DUPLICADO" }
            
            $html += @"
                    <div class="file-item $tag">
                        <div class="file-path">$($file.FullName)</div>
                        <div class="file-tag $tag">$tagText</div>
                    </div>
"@
            $isFirst = $false
        }
        
        $html += @"
                </div>
            </div>
"@
    }
    
    $html += @"
        </div>
        
        <div class="footer">
            <p>Optimizador de Computadora - Monitor de Duplicados</p>
            <p>Ruta escaneada: $($ScanResult.ScanPath)</p>
            <p>Algoritmo: $($ScanResult.Algorithm)</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Guardar archivo
    try {
        $html | Out-File -FilePath $reportPath -Encoding UTF8 -ErrorAction Stop
        Write-Host "  [✓] Reporte generado: $reportPath" -ForegroundColor Green
        Write-Log "Reporte HTML generado: $reportPath" "SUCCESS"
        
        # Preguntar si desea abrir
        Write-Host ""
        $openReport = Read-Host "¿Desea abrir el reporte en el navegador? (S/N)"
        
        if ($openReport -eq "S" -or $openReport -eq "s") {
            Start-Process $reportPath
        }
    }
    catch {
        Write-Host "  [✗] Error al generar reporte: $_" -ForegroundColor Red
        Write-Log "Error generando reporte HTML: $_" "ERROR"
    }
}

function Export-DuplicatesJSON {
    <#
    .SYNOPSIS
        Exporta resultados en formato JSON
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ScanResult
    )
    
    Write-Host "`n[*] Exportando a JSON..." -ForegroundColor Cyan
    
    $jsonPath = "$env:USERPROFILE\OptimizadorPC-Duplicados-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    
    try {
        # Preparar datos para JSON
        $exportData = @{
            Metadata = @{
                ScanDate = $ScanResult.ScanDate
                ScanPath = $ScanResult.ScanPath
                Algorithm = $ScanResult.Algorithm
                Version = $Global:DuplicatesScriptVersion
            }
            Summary = @{
                TotalFiles = $ScanResult.TotalFiles
                DuplicateFiles = $ScanResult.DuplicateFiles
                DuplicateGroups = $ScanResult.DuplicateGroups
                WastedSpaceBytes = $ScanResult.WastedSpaceBytes
                WastedSpaceMB = $ScanResult.WastedSpaceMB
                WastedSpaceGB = $ScanResult.WastedSpaceGB
            }
            Groups = @()
        }
        
        foreach ($group in $ScanResult.Groups) {
            $exportData.Groups += @{
                Hash = $group.Key
                Files = $group.Value
            }
        }
        
        $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8 -ErrorAction Stop
        
        Write-Host "  [✓] JSON exportado: $jsonPath" -ForegroundColor Green
        Write-Log "Datos exportados a JSON: $jsonPath" "SUCCESS"
    }
    catch {
        Write-Host "  [✗] Error al exportar JSON: $_" -ForegroundColor Red
        Write-Log "Error exportando JSON: $_" "ERROR"
    }
}

function Compress-DuplicateFiles {
    <#
    .SYNOPSIS
        Comprime archivos duplicados en un archivo ZIP antes de eliminarlos
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ScanResult
    )
    
    Write-Host "`n[*] Comprimiendo duplicados antes de eliminar..." -ForegroundColor Cyan
    
    $zipPath = "$env:USERPROFILE\OptimizadorPC-Duplicados-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    
    try {
        Add-Type -Assembly System.IO.Compression.FileSystem
        
        $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
        
        $fileCount = 0
        
        foreach ($group in $ScanResult.Groups) {
            $files = $group.Value
            
            # Comprimir todos excepto el primero (original)
            for ($i = 1; $i -lt $files.Count; $i++) {
                $file = $files[$i]
                
                try {
                    $entryName = "$($group.Key.Substring(0,8))_$($file.Name)"
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName) | Out-Null
                    
                    $fileCount++
                    
                    if ($fileCount % 10 -eq 0) {
                        Write-Host "  [*] Comprimidos: $fileCount archivos..." -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Log "Error comprimiendo $($file.FullName): $_" "WARNING"
                }
            }
        }
        
        $zip.Dispose()
        
        $zipSizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
        
        Write-Host "  [✓] Backup creado: $zipPath" -ForegroundColor Green
        Write-Host "  [✓] $fileCount archivo(s) comprimido(s) ($zipSizeMB MB)" -ForegroundColor Green
        Write-Log "Backup de duplicados creado: $zipPath, $fileCount archivos" "SUCCESS"
    }
    catch {
        Write-Host "  [✗] Error al crear backup: $_" -ForegroundColor Red
        Write-Log "Error creando backup ZIP: $_" "ERROR"
    }
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 🔍 Buscar Duplicados (MD5)                ║" -ForegroundColor Cyan
        Write-Host "  ║  [2] 🔐 Buscar Duplicados (SHA256)             ║" -ForegroundColor Blue
        Write-Host "  ║  [3] 📊 Mostrar Grupos de Duplicados           ║" -ForegroundColor Yellow
        Write-Host "  ║  [4] 🗑️  Eliminar Duplicados                   ║" -ForegroundColor Red
        Write-Host "  ║  [5] 📦 Comprimir y Eliminar Duplicados        ║" -ForegroundColor Magenta
        Write-Host "  ║  [6] 📄 Exportar Reporte HTML                  ║" -ForegroundColor Green
        Write-Host "  ║  [7] 💾 Exportar Datos JSON                    ║" -ForegroundColor Cyan
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                $path = Read-Host "`n  Ingrese la ruta a escanear (o Enter para carpeta actual)"
                if ([string]::IsNullOrWhiteSpace($path)) {
                    $path = Get-Location
                }
                
                $recursive = Read-Host "  ¿Escaneo recursivo? (S/N)"
                $isRecursive = $recursive -eq "S" -or $recursive -eq "s"
                
                $minSizeStr = Read-Host "  Tamaño mínimo en MB (Enter para incluir todos)"
                $minSize = if ([string]::IsNullOrWhiteSpace($minSizeStr)) { 0 } else { [int64]$minSizeStr * 1MB }
                
                $Global:LastScanResult = Get-DuplicateFiles -Path $path -Algorithm "MD5" -Recursive:$isRecursive -MinSizeBytes $minSize
                
                if ($Global:LastScanResult) {
                    Show-DuplicateGroups -ScanResult $Global:LastScanResult
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '2' {
                $path = Read-Host "`n  Ingrese la ruta a escanear (o Enter para carpeta actual)"
                if ([string]::IsNullOrWhiteSpace($path)) {
                    $path = Get-Location
                }
                
                $recursive = Read-Host "  ¿Escaneo recursivo? (S/N)"
                $isRecursive = $recursive -eq "S" -or $recursive -eq "s"
                
                $minSizeStr = Read-Host "  Tamaño mínimo en MB (Enter para incluir todos)"
                $minSize = if ([string]::IsNullOrWhiteSpace($minSizeStr)) { 0 } else { [int64]$minSizeStr * 1MB }
                
                $Global:LastScanResult = Get-DuplicateFiles -Path $path -Algorithm "SHA256" -Recursive:$isRecursive -MinSizeBytes $minSize
                
                if ($Global:LastScanResult) {
                    Show-DuplicateGroups -ScanResult $Global:LastScanResult
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                if ($Global:LastScanResult) {
                    Show-DuplicateGroups -ScanResult $Global:LastScanResult
                }
                else {
                    Write-Host "`n  [!] Primero debe realizar un escaneo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                if ($Global:LastScanResult) {
                    Write-Host "`n  Estrategias disponibles:" -ForegroundColor Cyan
                    Write-Host "    [1] KeepFirst - Mantener el primero encontrado"
                    Write-Host "    [2] KeepNewest - Mantener el más reciente"
                    Write-Host "    [3] KeepOldest - Mantener el más antiguo"
                    
                    $strategyChoice = Read-Host "`n  Seleccione estrategia (1-3)"
                    
                    $strategy = switch ($strategyChoice) {
                        '1' { "KeepFirst" }
                        '2' { "KeepNewest" }
                        '3' { "KeepOldest" }
                        default { "KeepFirst" }
                    }
                    
                    Remove-DuplicateFiles -ScanResult $Global:LastScanResult -KeepStrategy $strategy
                }
                else {
                    Write-Host "`n  [!] Primero debe realizar un escaneo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                if ($Global:LastScanResult) {
                    Compress-DuplicateFiles -ScanResult $Global:LastScanResult
                    
                    Write-Host "`n  [?] ¿Desea eliminar los duplicados ahora? (S/N)" -ForegroundColor Yellow
                    $delete = Read-Host
                    
                    if ($delete -eq "S" -or $delete -eq "s") {
                        Remove-DuplicateFiles -ScanResult $Global:LastScanResult -KeepStrategy "KeepFirst"
                    }
                }
                else {
                    Write-Host "`n  [!] Primero debe realizar un escaneo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                if ($Global:LastScanResult) {
                    Export-DuplicatesReport -ScanResult $Global:LastScanResult
                }
                else {
                    Write-Host "`n  [!] Primero debe realizar un escaneo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '7' {
                if ($Global:LastScanResult) {
                    Export-DuplicatesJSON -ScanResult $Global:LastScanResult
                }
                else {
                    Write-Host "`n  [!] Primero debe realizar un escaneo" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                Write-Host "`n  [✓] Saliendo del Gestor de Duplicados..." -ForegroundColor Green
                Write-Log "Gestor de Duplicados cerrado" "INFO"
                return
            }
            default {
                Write-Host "`n  [✗] Opción inválida" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Iniciar menú
Show-Menu

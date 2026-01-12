<#
.SYNOPSIS
    Gestor Inteligente de Aplicaciones para Windows
.DESCRIPTION
    Lista, analiza y desinstala aplicaciones con detección de bloatware,
    exportación de listas y soporte para winget/chocolatey.
.NOTES
    Versión: 2.9.0
    Autor: Fernando Farfan
    Requiere: PowerShell 5.1+, Windows 10/11, Permisos de Administrador
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$Global:AppListPath = "$env:USERPROFILE\OptimizadorPC-AppList.json"
$Global:AppScriptVersion = "4.0.0"

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
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                                              ║" -ForegroundColor Green
    Write-Host "  ║          📦 GESTOR INTELIGENTE DE APLICACIONES              ║" -ForegroundColor White
    Write-Host "  ║                      Versión $Global:AppScriptVersion                      ║" -ForegroundColor Green
    Write-Host "  ║                                                              ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

function Get-InstalledApplications {
    <#
    .SYNOPSIS
        Obtiene lista completa de aplicaciones instaladas con tamaño y fecha
    #>
    param(
        [switch]$IncludeBloatware
    )
    
    Write-Host "`n[*] Analizando aplicaciones instaladas..." -ForegroundColor Cyan
    Write-Log "Iniciando análisis de aplicaciones instaladas" "INFO"
    
    $apps = @()
    
    # Obtener aplicaciones Win32 (Registry)
    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        $regApps = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.UninstallString } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, EstimatedSize, UninstallString, PSPath
        
        foreach ($app in $regApps) {
            $sizeInMB = if ($app.EstimatedSize) { [math]::Round($app.EstimatedSize / 1024, 2) } else { 0 }
            
            $appInfo = [PSCustomObject]@{
                Name = $app.DisplayName
                Version = $app.DisplayVersion
                Publisher = $app.Publisher
                InstallDate = $app.InstallDate
                SizeMB = $sizeInMB
                UninstallString = $app.UninstallString
                Type = "Win32"
                IsBloatware = $false
                LastUsed = $null
            }
            
            $apps += $appInfo
        }
    }
    
    # Obtener aplicaciones UWP/Store
    try {
        $uwpApps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Select-Object Name, Version, Publisher, InstallLocation, PackageFullName
        
        foreach ($uwpApp in $uwpApps) {
            # Calcular tamaño de carpeta de instalación
            $sizeInMB = 0
            if ($uwpApp.InstallLocation -and (Test-Path $uwpApp.InstallLocation)) {
                try {
                    $size = (Get-ChildItem -Path $uwpApp.InstallLocation -Recurse -File -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum).Sum
                    $sizeInMB = [math]::Round($size / 1MB, 2)
                }
                catch { $sizeInMB = 0 }
            }
            
            $appInfo = [PSCustomObject]@{
                Name = $uwpApp.Name
                Version = $uwpApp.Version
                Publisher = $uwpApp.Publisher
                InstallDate = $null
                SizeMB = $sizeInMB
                UninstallString = "Get-AppxPackage -Name '$($uwpApp.Name)' -AllUsers | Remove-AppxPackage"
                Type = "UWP"
                IsBloatware = $false
                LastUsed = $null
                PackageFullName = $uwpApp.PackageFullName
            }
            
            $apps += $appInfo
        }
    }
    catch {
        Write-Log "Error al obtener aplicaciones UWP: $_" "WARNING"
    }
    
    # Detectar bloatware
    if ($IncludeBloatware) {
        $bloatwareList = @(
            "*CandyCrush*", "*Xbox*", "*BingNews*", "*BingSports*", "*BingWeather*",
            "*GetHelp*", "*Getstarted*", "*Messaging*", "*Office.OneNote*",
            "*People*", "*SkypeApp*", "*Solitaire*", "*WindowsFeedback*",
            "*YourPhone*", "*3DBuilder*", "*Alarms*", "*Camera*",
            "*Maps*", "*SoundRecorder*", "*ZuneMusic*", "*ZuneVideo*",
            "*McAfee*", "*Norton*", "*WildTangent*", "*Keeper*"
        )
        
        foreach ($app in $apps) {
            foreach ($bloat in $bloatwareList) {
                if ($app.Name -like $bloat) {
                    $app.IsBloatware = $true
                    break
                }
            }
        }
    }
    
    # Remover duplicados y ordenar
    $apps = $apps | Sort-Object -Property Name -Unique | Sort-Object -Property SizeMB -Descending
    
    Write-Host "  [✓] Encontradas $($apps.Count) aplicaciones" -ForegroundColor Green
    if ($IncludeBloatware) {
        $bloatCount = ($apps | Where-Object { $_.IsBloatware }).Count
        Write-Host "  [!] Detectadas $bloatCount aplicaciones de bloatware" -ForegroundColor Yellow
    }
    Write-Log "Encontradas $($apps.Count) aplicaciones instaladas" "SUCCESS"
    
    return $apps
}

function Show-ApplicationsList {
    <#
    .SYNOPSIS
        Muestra lista de aplicaciones con detalles
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Applications,
        
        [switch]$OnlyBloatware
    )
    
    if ($OnlyBloatware) {
        $Applications = $Applications | Where-Object { $_.IsBloatware }
    }
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                      APLICACIONES INSTALADAS                             ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $index = 1
    $totalSize = 0
    
    foreach ($app in $Applications) {
        $color = if ($app.IsBloatware) { "Red" } else { "White" }
        $bloatFlag = if ($app.IsBloatware) { " [BLOATWARE]" } else { "" }
        
        Write-Host "[$index] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($app.Name)$bloatFlag" -ForegroundColor $color
        Write-Host "    Versión: $($app.Version) | Tamaño: $($app.SizeMB) MB | Tipo: $($app.Type)" -ForegroundColor Gray
        Write-Host "    Editor: $($app.Publisher)" -ForegroundColor DarkGray
        Write-Host ""
        
        $totalSize += $app.SizeMB
        $index++
    }
    
    Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Total: $($Applications.Count) aplicaciones | Tamaño total: $([math]::Round($totalSize/1024, 2)) GB" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Uninstall-Application {
    <#
    .SYNOPSIS
        Desinstala una aplicación
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Application
    )
    
    Write-Host "`n[*] Desinstalando: $($Application.Name)..." -ForegroundColor Cyan
    Write-Log "Iniciando desinstalación de: $($Application.Name)" "INFO"
    
    try {
        if ($Application.Type -eq "UWP") {
            # Desinstalar aplicación UWP
            Invoke-Expression $Application.UninstallString -ErrorAction Stop
            Write-Host "  [✓] $($Application.Name) desinstalada correctamente" -ForegroundColor Green
            Write-Log "Aplicación UWP desinstalada: $($Application.Name)" "SUCCESS"
            return $true
        }
        else {
            # Desinstalar aplicación Win32
            $uninstallString = $Application.UninstallString
            
            # Determinar el tipo de desinstalador
            if ($uninstallString -match "msiexec") {
                # MSI Installer
                if ($uninstallString -match "\{.*\}") {
                    $productCode = $matches[0]
                    $arguments = "/x $productCode /qn /norestart"
                    Start-Process "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow
                }
            }
            elseif ($uninstallString -match '\.exe') {
                # EXE Installer - intentar desinstalación silenciosa
                $exePath = $uninstallString -replace '"', ''
                
                # Argumentos comunes de desinstalación silenciosa
                $silentArgs = @("/S", "/SILENT", "/VERYSILENT", "/quiet", "/q", "/uninstall")
                
                foreach ($arg in $silentArgs) {
                    try {
                        Start-Process $exePath -ArgumentList $arg -Wait -NoNewWindow -ErrorAction Stop
                        Write-Host "  [✓] $($Application.Name) desinstalada correctamente" -ForegroundColor Green
                        Write-Log "Aplicación Win32 desinstalada: $($Application.Name)" "SUCCESS"
                        return $true
                    }
                    catch {
                        continue
                    }
                }
                
                # Si ningún argumento funcionó, ejecutar sin argumentos
                Start-Process $exePath -Wait
            }
            else {
                Write-Host "  [!] Tipo de desinstalador no reconocido" -ForegroundColor Yellow
                Write-Host "  [i] String de desinstalación: $uninstallString" -ForegroundColor Gray
                return $false
            }
            
            Write-Host "  [✓] $($Application.Name) procesada" -ForegroundColor Green
            Write-Log "Aplicación Win32 procesada: $($Application.Name)" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Host "  [✗] Error al desinstalar: $_" -ForegroundColor Red
        Write-Log "Error al desinstalar $($Application.Name): $_" "ERROR"
        return $false
    }
}

function Uninstall-BulkApplications {
    <#
    .SYNOPSIS
        Desinstala múltiples aplicaciones por índices
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Applications,
        
        [Parameter(Mandatory=$true)]
        [string]$Indices
    )
    
    # Parsear índices (soporta rangos: 1-5, listas: 1,3,5)
    $selectedIndices = @()
    
    foreach ($part in ($Indices -split ',')) {
        if ($part -match '(\d+)-(\d+)') {
            $start = [int]$matches[1]
            $end = [int]$matches[2]
            $selectedIndices += $start..$end
        }
        else {
            $selectedIndices += [int]$part
        }
    }
    
    $selectedIndices = $selectedIndices | Sort-Object -Unique
    
    Write-Host "`n[*] Se desinstalarán $($selectedIndices.Count) aplicaciones..." -ForegroundColor Cyan
    Write-Host "[!] ATENCIÓN: Este proceso puede tardar varios minutos" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "¿Confirmar desinstalación masiva? (S/N)"
    
    if ($confirm -ne 'S' -and $confirm -ne 's') {
        Write-Host "  [i] Operación cancelada" -ForegroundColor Yellow
        return
    }
    
    $successCount = 0
    $failCount = 0
    
    foreach ($index in $selectedIndices) {
        if ($index -ge 1 -and $index -le $Applications.Count) {
            $app = $Applications[$index - 1]
            
            if (Uninstall-Application -Application $app) {
                $successCount++
            }
            else {
                $failCount++
            }
            
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║            RESUMEN DE DESINSTALACIÓN MASIVA                  ║" -ForegroundColor White
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║  ✓ Exitosas: $successCount                                         ║" -ForegroundColor Green
    Write-Host "║  ✗ Fallidas: $failCount                                          ║" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-Log "Desinstalación masiva completada: $successCount exitosas, $failCount fallidas" "INFO"
}

function Export-ApplicationList {
    <#
    .SYNOPSIS
        Exporta lista de aplicaciones a JSON
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Applications
    )
    
    Write-Host "`n[*] Exportando lista de aplicaciones..." -ForegroundColor Cyan
    
    $exportData = @{
        ExportDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ComputerName = $env:COMPUTERNAME
        TotalApplications = $Applications.Count
        Applications = $Applications
    }
    
    try {
        $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $Global:AppListPath -Encoding UTF8
        Write-Host "  [✓] Lista exportada: $Global:AppListPath" -ForegroundColor Green
        Write-Log "Lista de aplicaciones exportada a JSON" "SUCCESS"
        return $true
    }
    catch {
        Write-Host "  [✗] Error al exportar: $_" -ForegroundColor Red
        Write-Log "Error al exportar lista de aplicaciones: $_" "ERROR"
        return $false
    }
}

function Import-ApplicationList {
    <#
    .SYNOPSIS
        Importa lista de aplicaciones desde JSON
    #>
    
    if (-not (Test-Path $Global:AppListPath)) {
        Write-Host "  [✗] No se encontró archivo de exportación" -ForegroundColor Red
        return $null
    }
    
    try {
        $importData = Get-Content -Path $Global:AppListPath -Raw | ConvertFrom-Json
        Write-Host "  [✓] Lista importada: $($importData.TotalApplications) aplicaciones" -ForegroundColor Green
        Write-Host "  [i] Exportada desde: $($importData.ComputerName) el $($importData.ExportDate)" -ForegroundColor Cyan
        Write-Log "Lista de aplicaciones importada desde JSON" "SUCCESS"
        return $importData.Applications
    }
    catch {
        Write-Host "  [✗] Error al importar: $_" -ForegroundColor Red
        Write-Log "Error al importar lista de aplicaciones: $_" "ERROR"
        return $null
    }
}

function Test-PackageManager {
    <#
    .SYNOPSIS
        Verifica si winget o chocolatey están instalados
    #>
    
    $managers = @{
        Winget = $false
        Chocolatey = $false
    }
    
    # Test winget
    try {
        $wingetVersion = winget --version 2>$null
        if ($wingetVersion) {
            $managers.Winget = $true
        }
    }
    catch { }
    
    # Test chocolatey
    try {
        $chocoVersion = choco --version 2>$null
        if ($chocoVersion) {
            $managers.Chocolatey = $true
        }
    }
    catch { }
    
    return $managers
}

function Update-ApplicationsWithWinget {
    <#
    .SYNOPSIS
        Actualiza aplicaciones usando winget
    #>
    
    Write-Host "`n[*] Buscando actualizaciones con winget..." -ForegroundColor Cyan
    Write-Log "Iniciando actualización con winget" "INFO"
    
    try {
        $upgradable = winget upgrade --include-unknown 2>$null
        
        Write-Host "`n[*] Aplicaciones con actualizaciones disponibles:" -ForegroundColor Yellow
        Write-Host $upgradable
        
        Write-Host "`n[?] ¿Actualizar todas las aplicaciones? (S/N)" -ForegroundColor Cyan
        $confirm = Read-Host
        
        if ($confirm -eq 'S' -or $confirm -eq 's') {
            Write-Host "`n[*] Actualizando aplicaciones..." -ForegroundColor Cyan
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
            Write-Host "  [✓] Actualización completada" -ForegroundColor Green
            Write-Log "Aplicaciones actualizadas con winget" "SUCCESS"
        }
    }
    catch {
        Write-Host "  [✗] Error al usar winget: $_" -ForegroundColor Red
        Write-Log "Error al actualizar con winget: $_" "ERROR"
    }
}

function Get-UnusedApplications {
    <#
    .SYNOPSIS
        Detecta aplicaciones no usadas en los últimos 90 días
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Applications
    )
    
    Write-Host "`n[*] Analizando aplicaciones no usadas (>90 días)..." -ForegroundColor Cyan
    
    $unusedApps = @()
    $threshold = (Get-Date).AddDays(-90)
    
    foreach ($app in $Applications) {
        if ($app.InstallDate) {
            try {
                # Parsear fecha (formato YYYYMMDD)
                $installDateStr = $app.InstallDate.ToString()
                if ($installDateStr.Length -eq 8) {
                    $year = $installDateStr.Substring(0, 4)
                    $month = $installDateStr.Substring(4, 2)
                    $day = $installDateStr.Substring(6, 2)
                    $installDate = Get-Date -Year $year -Month $month -Day $day
                    
                    if ($installDate -lt $threshold) {
                        $daysOld = ((Get-Date) - $installDate).Days
                        $app | Add-Member -NotePropertyName DaysOld -NotePropertyValue $daysOld -Force
                        $unusedApps += $app
                    }
                }
            }
            catch { }
        }
    }
    
    if ($unusedApps.Count -gt 0) {
        Write-Host "  [!] Encontradas $($unusedApps.Count) aplicaciones antiguas" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($app in ($unusedApps | Sort-Object -Property DaysOld -Descending | Select-Object -First 10)) {
            Write-Host "  - $($app.Name)" -ForegroundColor Yellow
            Write-Host "    Instalada hace $($app.DaysOld) días | Tamaño: $($app.SizeMB) MB" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  [✓] No se encontraron aplicaciones antiguas" -ForegroundColor Green
    }
    
    return $unusedApps
}

function Show-Menu {
    $apps = $null
    
    while ($true) {
        Show-Banner
        
        Write-Host "  ╔════════════════════════════════════════════════╗" -ForegroundColor White
        Write-Host "  ║            MENÚ DE OPCIONES                    ║" -ForegroundColor White
        Write-Host "  ╠════════════════════════════════════════════════╣" -ForegroundColor White
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ║  [1] 📋 Listar Todas las Aplicaciones          ║" -ForegroundColor Cyan
        Write-Host "  ║  [2] 🗑️  Listar Solo Bloatware                 ║" -ForegroundColor Red
        Write-Host "  ║  [3] ❌ Desinstalar Una Aplicación             ║" -ForegroundColor Yellow
        Write-Host "  ║  [4] 💣 Desinstalar Múltiples (Masivo)         ║" -ForegroundColor Magenta
        Write-Host "  ║  [5] 🧹 Desinstalar Todo el Bloatware          ║" -ForegroundColor Red
        Write-Host "  ║  [6] 📤 Exportar Lista de Apps                 ║" -ForegroundColor Green
        Write-Host "  ║  [7] 📥 Importar Lista de Apps                 ║" -ForegroundColor Blue
        Write-Host "  ║  [8] 🔄 Actualizar Apps (winget)               ║" -ForegroundColor Cyan
        Write-Host "  ║  [9] 📊 Ver Apps No Usadas (>90 días)          ║" -ForegroundColor Yellow
        Write-Host "  ║  [0] ❌ Salir                                   ║" -ForegroundColor Gray
        Write-Host "  ║                                                ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════╝" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "  Seleccione una opción"
        
        switch ($choice) {
            '1' {
                $apps = Get-InstalledApplications -IncludeBloatware
                Show-ApplicationsList -Applications $apps
                Read-Host "`nPresione ENTER para continuar"
            }
            '2' {
                if (-not $apps) {
                    $apps = Get-InstalledApplications -IncludeBloatware
                }
                Show-ApplicationsList -Applications $apps -OnlyBloatware
                Read-Host "`nPresione ENTER para continuar"
            }
            '3' {
                if (-not $apps) {
                    $apps = Get-InstalledApplications -IncludeBloatware
                }
                Show-ApplicationsList -Applications $apps
                
                $index = Read-Host "`nIngrese el número de la aplicación a desinstalar (0 para cancelar)"
                
                if ([int]$index -ge 1 -and [int]$index -le $apps.Count) {
                    $selectedApp = $apps[[int]$index - 1]
                    
                    Write-Host "`n[!] Se desinstalará: $($selectedApp.Name)" -ForegroundColor Yellow
                    $confirm = Read-Host "¿Confirmar? (S/N)"
                    
                    if ($confirm -eq 'S' -or $confirm -eq 's') {
                        Uninstall-Application -Application $selectedApp
                    }
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '4' {
                if (-not $apps) {
                    $apps = Get-InstalledApplications -IncludeBloatware
                }
                Show-ApplicationsList -Applications $apps
                
                Write-Host "`n[i] Ejemplos: 1,3,5 (lista) o 1-10 (rango)" -ForegroundColor Cyan
                $indices = Read-Host "Ingrese los números de aplicaciones a desinstalar"
                
                if ($indices) {
                    Uninstall-BulkApplications -Applications $apps -Indices $indices
                    # Recargar lista
                    $apps = $null
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '5' {
                if (-not $apps) {
                    $apps = Get-InstalledApplications -IncludeBloatware
                }
                
                $bloatware = $apps | Where-Object { $_.IsBloatware }
                
                if ($bloatware.Count -eq 0) {
                    Write-Host "`n  [✓] No se detectó bloatware en el sistema" -ForegroundColor Green
                }
                else {
                    Show-ApplicationsList -Applications $bloatware
                    
                    Write-Host "`n[!] ATENCIÓN: Se desinstalarán $($bloatware.Count) aplicaciones de bloatware" -ForegroundColor Red
                    $confirm = Read-Host "¿Confirmar desinstalación de TODO el bloatware? (S/N)"
                    
                    if ($confirm -eq 'S' -or $confirm -eq 's') {
                        $successCount = 0
                        foreach ($app in $bloatware) {
                            if (Uninstall-Application -Application $app) {
                                $successCount++
                            }
                        }
                        
                        Write-Host "`n[✓] Desinstaladas $successCount de $($bloatware.Count) aplicaciones de bloatware" -ForegroundColor Green
                        $apps = $null
                    }
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '6' {
                if (-not $apps) {
                    $apps = Get-InstalledApplications -IncludeBloatware
                }
                Export-ApplicationList -Applications $apps
                Read-Host "`nPresione ENTER para continuar"
            }
            '7' {
                $importedApps = Import-ApplicationList
                if ($importedApps) {
                    Show-ApplicationsList -Applications $importedApps
                }
                Read-Host "`nPresione ENTER para continuar"
            }
            '8' {
                $managers = Test-PackageManager
                
                if ($managers.Winget) {
                    Update-ApplicationsWithWinget
                }
                elseif ($managers.Chocolatey) {
                    Write-Host "`n[i] Chocolatey detectado. Ejecute: choco upgrade all" -ForegroundColor Cyan
                }
                else {
                    Write-Host "`n[✗] No se detectó winget ni chocolatey" -ForegroundColor Red
                    Write-Host "[i] Instale winget desde Microsoft Store" -ForegroundColor Yellow
                }
                
                Read-Host "`nPresione ENTER para continuar"
            }
            '9' {
                if (-not $apps) {
                    $apps = Get-InstalledApplications
                }
                Get-UnusedApplications -Applications $apps
                Read-Host "`nPresione ENTER para continuar"
            }
            '0' {
                Write-Host "`n  [✓] Saliendo del Gestor de Aplicaciones..." -ForegroundColor Green
                Write-Log "Gestor de Aplicaciones cerrado" "INFO"
                return
            }
            default {
                Write-Host "`n  [✗] Opción inválida" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "`n[✗] ERROR: Se requieren permisos de Administrador" -ForegroundColor Red
    Write-Host "[i] Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'" -ForegroundColor Yellow
    Read-Host "`nPresione ENTER para salir"
    exit 1
}

# Iniciar menú
Show-Menu

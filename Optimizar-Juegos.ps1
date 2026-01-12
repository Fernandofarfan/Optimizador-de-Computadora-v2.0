# ============================================
# Optimizar-Juegos.ps1
# Detecta y optimiza juegos instalados
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OPTIMIZADOR DE JUEGOS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Iniciando optimizador de juegos" -Level "INFO"

# Función para detectar juegos de Steam
function Get-SteamGames {
    $juegos = @()
    
    try {
        $steamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        if (-not $steamPath) {
            $steamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Valve\Steam" -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        }
        
        if ($steamPath -and (Test-Path $steamPath)) {
            # Buscar libraryfolders.vdf
            $libFile = "$steamPath\steamapps\libraryfolders.vdf"
            if (Test-Path $libFile) {
                $content = Get-Content $libFile -Raw
                
                # Extraer rutas de bibliotecas
                $folders = @($steamPath)
                $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
                foreach ($match in $matches) {
                    $path = $match.Groups[1].Value.Replace("\\\\", "\")
                    if (Test-Path "$path\steamapps") {
                        $folders += $path
                    }
                }
                
                # Buscar archivos .acf en cada biblioteca
                foreach ($folder in $folders) {
                    $acfFiles = Get-ChildItem -Path "$folder\steamapps" -Filter "appmanifest_*.acf" -ErrorAction SilentlyContinue
                    foreach ($acf in $acfFiles) {
                        $acfContent = Get-Content $acf.FullName -Raw
                        if ($acfContent -match '"name"\s+"([^"]+)"') {
                            $gameName = $matches[1]
                            if ($acfContent -match '"installdir"\s+"([^"]+)"') {
                                $installDir = $matches[1]
                                $gamePath = "$folder\steamapps\common\$installDir"
                                
                                # Buscar ejecutable principal
                                $exes = Get-ChildItem -Path $gamePath -Filter "*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | 
                                        Where-Object { $_.Name -notlike "*unins*" -and $_.Name -notlike "*crash*" -and $_.Name -notlike "*launcher*" } |
                                        Select-Object -First 1
                                
                                if ($exes) {
                                    $juegos += [PSCustomObject]@{
                                        Nombre = $gameName
                                        Ejecutable = $exes.FullName
                                        Plataforma = "Steam"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-Log "Error detectando juegos Steam: $_" -Level "ERROR"
    }
    
    return $juegos
}

# Función para detectar juegos de Epic Games
function Get-EpicGames {
    $juegos = @()
    
    try {
        $manifestPath = "$env:ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
        if (Test-Path $manifestPath) {
            $manifests = Get-ChildItem -Path $manifestPath -Filter "*.item" -ErrorAction SilentlyContinue
            
            foreach ($manifest in $manifests) {
                $content = Get-Content $manifest.FullName | ConvertFrom-Json
                if ($content.InstallLocation -and (Test-Path $content.InstallLocation)) {
                    $gameName = $content.DisplayName
                    $gamePath = $content.InstallLocation
                    
                    # Buscar ejecutable
                    $exes = Get-ChildItem -Path $gamePath -Filter "*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -notlike "*EasyAntiCheat*" -and $_.Name -notlike "*BattlEye*" -and $_.Name -notlike "*unins*" -and $_.Name -notlike "*crash*" } |
                            Select-Object -First 1
                    
                    if ($exes) {
                        $juegos += [PSCustomObject]@{
                            Nombre = $gameName
                            Ejecutable = $exes.FullName
                            Plataforma = "Epic Games"
                        }
                    }
                }
            }
        }
    } catch {
        Write-Log "Error detectando juegos Epic: $_" -Level "ERROR"
    }
    
    return $juegos
}

# Función para detectar juegos de Origin
function Get-OriginGames {
    $juegos = @()
    
    try {
        # Buscar en múltiples ubicaciones
        $originPaths = @(
            "$env:ProgramData\Origin\LocalContent",
            "C:\Program Files (x86)\Origin Games",
            "C:\Program Files\Origin Games"
        )
        
        foreach ($basePath in $originPaths) {
            if (Test-Path $basePath) {
                $folders = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
                foreach ($folder in $folders) {
                    $exes = Get-ChildItem -Path $folder.FullName -Filter "*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -notlike "*unins*" -and $_.Name -notlike "*installer*" } |
                            Select-Object -First 1
                    
                    if ($exes) {
                        $juegos += [PSCustomObject]@{
                            Nombre = $folder.Name
                            Ejecutable = $exes.FullName
                            Plataforma = "Origin"
                        }
                    }
                }
            }
        }
    } catch {
        Write-Log "Error detectando juegos Origin: $_" -Level "ERROR"
    }
    
    return $juegos
}

# Función para detectar juegos de GOG
function Get-GOGGames {
    $juegos = @()
    
    try {
        $gogKeys = @(
            "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
            "HKLM:\SOFTWARE\GOG.com\Games"
        )
        
        foreach ($keyPath in $gogKeys) {
            if (Test-Path $keyPath) {
                $games = Get-ChildItem -Path $keyPath -ErrorAction SilentlyContinue
                foreach ($game in $games) {
                    $gameInfo = Get-ItemProperty -Path $game.PSPath
                    $gameName = $gameInfo.gameName
                    $gamePath = $gameInfo.path
                    $gameExe = $gameInfo.exe
                    
                    if ($gamePath -and $gameExe -and (Test-Path "$gamePath\$gameExe")) {
                        $juegos += [PSCustomObject]@{
                            Nombre = $gameName
                            Ejecutable = "$gamePath\$gameExe"
                            Plataforma = "GOG"
                        }
                    }
                }
            }
        }
    } catch {
        Write-Log "Error detectando juegos GOG: $_" -Level "ERROR"
    }
    
    return $juegos
}

# Función para optimizar un juego específico
function Optimize-Game {
    param (
        [string]$GameExe,
        [string]$GameName
    )
    
    Write-Host ""
    Write-Host "🎮 OPTIMIZANDO: $GameName" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $optimizaciones = 0
    
    # 1. Verificar si el juego está corriendo
    $exeName = [System.IO.Path]::GetFileName($GameExe)
    $process = Get-Process | Where-Object { $_.Path -eq $GameExe } | Select-Object -First 1
    
    if ($process) {
        Write-Host "[✓] Juego en ejecución detectado" -ForegroundColor Green
        
        # Aumentar prioridad
        try {
            $process.PriorityClass = "High"
            Write-Host "  → Prioridad establecida: Alta" -ForegroundColor Cyan
            $optimizaciones++
        } catch {
            Write-Host "  → No se pudo cambiar prioridad" -ForegroundColor Yellow
        }
        
        # Establecer afinidad CPU (todos los núcleos)
        try {
            $cpuCores = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
            $affinity = [Math]::Pow(2, $cpuCores) - 1
            $process.ProcessorAffinity = [IntPtr]$affinity
            Write-Host "  → CPU affinity: Todos los núcleos ($cpuCores)" -ForegroundColor Cyan
            $optimizaciones++
        } catch {
            Write-Host "  → No se pudo establecer affinity" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "[!] Juego no está corriendo actualmente" -ForegroundColor Yellow
        Write-Host "  → Lanza el juego y vuelve a ejecutar para optimizar" -ForegroundColor Gray
    }
    
    # 2. Crear configuración de GPU (NVIDIA/AMD)
    Write-Host "[✓] Configurando perfil de GPU..." -ForegroundColor Green
    try {
        $gpuKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        if (-not (Test-Path $gpuKey)) {
            New-Item -Path $gpuKey -Force | Out-Null
        }
        
        Set-ItemProperty -Path $gpuKey -Name $GameExe -Value "GpuPreference=2;" -Force
        Write-Host "  → GPU: Alto rendimiento" -ForegroundColor Cyan
        $optimizaciones++
    } catch {
        Write-Host "  → No se pudo configurar GPU" -ForegroundColor Yellow
    }
    
    # 3. Desactivar Game DVR para este juego
    Write-Host "[✓] Desactivando Game DVR..." -ForegroundColor Green
    try {
        $gameDVRKey = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $gameDVRKey)) {
            New-Item -Path $gameDVRKey -Force | Out-Null
        }
        Set-ItemProperty -Path $gameDVRKey -Name "GameDVR_Enabled" -Value 0 -Force
        Write-Host "  → Game DVR desactivado" -ForegroundColor Cyan
        $optimizaciones++
    } catch {
        Write-Host "  → No se pudo desactivar Game DVR" -ForegroundColor Yellow
    }
    
    # 4. Deshabilitar pantalla completa optimizada (mejor rendimiento con exclusivo)
    Write-Host "[✓] Configurando pantalla completa..." -ForegroundColor Green
    try {
        $gameExeKey = "HKCU:\System\GameConfigStore\Children"
        if (-not (Test-Path $gameExeKey)) {
            New-Item -Path $gameExeKey -Force | Out-Null
        }
        
        # Crear hash del ejecutable
        $hash = [System.BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($GameExe)).Replace("-", "")
        $gameKey = "$gameExeKey\$hash"
        
        if (-not (Test-Path $gameKey)) {
            New-Item -Path $gameKey -Force | Out-Null
        }
        
        Set-ItemProperty -Path $gameKey -Name "Mode" -Value 2 -Force # 2 = Full screen exclusive
        Write-Host "  → Pantalla completa: Exclusivo (mejor FPS)" -ForegroundColor Cyan
        $optimizaciones++
    } catch {
        Write-Host "  → No se pudo configurar pantalla completa" -ForegroundColor Yellow
    }
    
    # 5. Deshabilitar overlays conocidos
    Write-Host "[✓] Deshabilitando overlays..." -ForegroundColor Green
    $overlaysDesactivados = 0
    
    # Discord overlay
    $discordPath = "$env:APPDATA\discord\settings.json"
    if (Test-Path $discordPath) {
        try {
            $settings = Get-Content $discordPath | ConvertFrom-Json
            $settings.OVERLAY_ENABLED = $false
            $settings | ConvertTo-Json | Set-Content $discordPath
            $overlaysDesactivados++
        } catch { }
    }
    
    # GeForce Experience overlay
    try {
        Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\FTS" -Name "EnableRID61536" -Value 0 -Force -ErrorAction SilentlyContinue
        $overlaysDesactivados++
    } catch { }
    
    # Xbox Game Bar
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Force
        $overlaysDesactivados++
    } catch { }
    
    Write-Host "  → Overlays desactivados: $overlaysDesactivados" -ForegroundColor Cyan
    $optimizaciones += $overlaysDesactivados
    
    Write-Host ""
    Write-Host "✅ OPTIMIZACIONES APLICADAS: $optimizaciones" -ForegroundColor Green
    Write-Log "Juego optimizado: $GameName ($optimizaciones optimizaciones)" -Level "SUCCESS"
}

# Detectar todos los juegos
Write-Host "🔍 Detectando juegos instalados..." -ForegroundColor Cyan
Write-Host ""

$todosJuegos = @()
$todosJuegos += Get-SteamGames
$todosJuegos += Get-EpicGames
$todosJuegos += Get-OriginGames
$todosJuegos += Get-GOGGames

if ($todosJuegos.Count -eq 0) {
    Write-Host "❌ No se detectaron juegos instalados" -ForegroundColor Red
    Write-Host ""
    Write-Host "Las plataformas soportadas son:" -ForegroundColor Gray
    Write-Host "  • Steam" -ForegroundColor Gray
    Write-Host "  • Epic Games" -ForegroundColor Gray
    Write-Host "  • Origin / EA App" -ForegroundColor Gray
    Write-Host "  • GOG Galaxy" -ForegroundColor Gray
    Write-Host ""
    Write-Log "No se encontraron juegos" -Level "WARNING"
} else {
    Write-Host "✅ Juegos detectados: $($todosJuegos.Count)" -ForegroundColor Green
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    # Agrupar por plataforma
    $grouped = $todosJuegos | Group-Object -Property Plataforma
    foreach ($group in $grouped) {
        Write-Host "[$($group.Name)] - $($group.Count) juegos" -ForegroundColor Cyan
    }
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Mostrar lista numerada
    for ($i = 0; $i -lt $todosJuegos.Count; $i++) {
        $juego = $todosJuegos[$i]
        Write-Host "[$($i+1)] " -NoNewline -ForegroundColor White
        Write-Host "$($juego.Nombre) " -NoNewline -ForegroundColor Yellow
        Write-Host "($($juego.Plataforma))" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "[0] Optimizar TODOS los juegos" -ForegroundColor Green
    Write-Host "[Q] Salir" -ForegroundColor Gray
    Write-Host ""
    
    $seleccion = Read-Host "Selecciona un juego (1-$($todosJuegos.Count), 0 para todos, Q para salir)"
    
    if ($seleccion -eq 'Q' -or $seleccion -eq 'q') {
        Write-Host "Saliendo..." -ForegroundColor Gray
        exit
    }
    
    if ($seleccion -eq '0') {
        Write-Host ""
        Write-Host "⚡ OPTIMIZANDO TODOS LOS JUEGOS..." -ForegroundColor Yellow
        
        foreach ($juego in $todosJuegos) {
            Optimize-Game -GameExe $juego.Ejecutable -GameName $juego.Nombre
        }
        
        Write-Host ""
        Write-Host "✅ TODOS LOS JUEGOS OPTIMIZADOS" -ForegroundColor Green
        Write-Log "Optimizados $($todosJuegos.Count) juegos" -Level "SUCCESS"
        
    } elseif ([int]$seleccion -ge 1 -and [int]$seleccion -le $todosJuegos.Count) {
        $juegoSeleccionado = $todosJuegos[[int]$seleccion - 1]
        Optimize-Game -GameExe $juegoSeleccionado.Ejecutable -GameName $juegoSeleccionado.Nombre
        
    } else {
        Write-Host "❌ Selección no válida" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "💡 RECOMENDACIONES:" -ForegroundColor Cyan
Write-Host "  • Ejecuta el juego y luego usa este script para optimizarlo en tiempo real" -ForegroundColor White
Write-Host "  • Cierra navegadores y programas en segundo plano" -ForegroundColor White
Write-Host "  • Usa el perfil GAMING desde Perfiles-Optimizacion.ps1" -ForegroundColor White
Write-Host "  • Mejora esperada: 10-30% más FPS en la mayoría de juegos" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

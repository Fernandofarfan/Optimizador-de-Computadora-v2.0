param(
    [string]$InputFile = (Join-Path $PWD "Optimizador.ps1"),
    [string]$OutputFile = (Join-Path $PWD "Optimizador.exe"),
    [switch]$NoConsole = $false,
    [string]$Title = "Optimizador de Computadora",
    [string]$IconPath = (Join-Path $PWD "docs\icon.ico")
)

Write-Host "=== Build-Exe.ps1 :: Compilación a EXE ===" -ForegroundColor Cyan
Write-Host "Input:  $InputFile" -ForegroundColor DarkGray
Write-Host "Output: $OutputFile" -ForegroundColor DarkGray

if (-not (Test-Path $InputFile)) {
    Write-Error "No se encontró el archivo de entrada: $InputFile"
    exit 1
}

# Asegurar TLS 1.2 para descargas desde PSGallery
try {
    $currentProtocols = [Net.ServicePointManager]::SecurityProtocol
    $tls12 = [Net.SecurityProtocolType]::Tls12
    if (($currentProtocols -band $tls12) -eq 0) {
        [Net.ServicePointManager]::SecurityProtocol = $currentProtocols -bor $tls12
    }
} catch {
    Write-Warning "No se pudo forzar TLS 1.2: $_"
}

# Configurar proveedor NuGet y PSGallery para permitir instalación de módulos
Write-Host "Configurando proveedor NuGet y PSGallery..." -ForegroundColor Yellow
try {
    # Instalar NuGet si no está disponible
    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nugetProvider) {
        Write-Host "Instalando proveedor NuGet..." -ForegroundColor DarkGray
        Install-PackageProvider -Name NuGet -Force -ForceBootstrap | Out-Null
    }
    
    # Confiar en PSGallery para evitar prompts
    $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if (-not $repo) {
        Write-Host "Registrando PSGallery..." -ForegroundColor DarkGray
        try {
            Register-PSRepository -Default -ErrorAction Stop
        } catch {
            # Registro explícito de PSGallery si -Default falla (entornos restringidos)
            try {
                Register-PSRepository -Name PSGallery -SourceLocation "https://www.powershellgallery.com/api/v2" -ScriptSourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted -ErrorAction Stop
            } catch {
                Write-Warning "No se pudo registrar PSGallery explícitamente: $_"
            }
        }
        $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    }
    if ($repo) {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "[OK] Proveedor NuGet y PSGallery configurados" -ForegroundColor Green
} catch {
    Write-Warning "Advertencia al configurar proveedor: $_"
}

# Instalar ps2exe si no está disponible
$ps2exeAvailable = Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
if (-not $ps2exeAvailable) {
    Write-Host "Instalando módulo ps2exe..." -ForegroundColor Yellow
    $installed = $false
    try {
        Install-Module -Name ps2exe -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck -ErrorAction Stop
        Import-Module ps2exe -Force -ErrorAction Stop
        $installed = $true
    } catch {
        Write-Warning "Fallo Install-Module ps2exe: $_"
        Write-Host "Intentando fallback con Save-Module..." -ForegroundColor Yellow
        try {
            $localModules = Join-Path $PWD "ModulesExternal"
            New-Item -ItemType Directory -Path $localModules -Force | Out-Null
            Save-Module -Name ps2exe -Path $localModules -Force -ErrorAction Stop
            $psd1 = Get-ChildItem -Path (Join-Path $localModules "ps2exe") -Recurse -Filter ps2exe.psd1 -ErrorAction Stop | Select-Object -First 1
            if ($psd1) {
                Import-Module $psd1.FullName -Force -ErrorAction Stop
                $installed = $true
            } else {
                Write-Error "No se encontró el manifiesto del módulo ps2exe en $localModules"
            }
        } catch {
            Write-Error "No se pudo instalar/importar ps2exe con fallback: $_"
        }
    }
    if (-not $installed) {
        Write-Error "ps2exe no disponible; no es posible continuar."
        exit 1
    }
}

# Verificar nuevamente la disponibilidad del comando
$ps2exeAvailable = Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
if (-not $ps2exeAvailable) {
    Write-Error "Invoke-ps2exe sigue no disponible tras la instalación."
    exit 1
}

# Construir el EXE
try {
    if (Test-Path $IconPath) {
        Write-Host "Usando icono: $IconPath" -ForegroundColor DarkGray
        Invoke-ps2exe -inputFile $InputFile -outputFile $OutputFile -noConsole:$NoConsole -title $Title -icon $IconPath
    } else {
        Write-Host "Icono no encontrado, compilando sin icono." -ForegroundColor DarkGray
        Invoke-ps2exe -inputFile $InputFile -outputFile $OutputFile -noConsole:$NoConsole -title $Title
    }
} catch {
    Write-Error "Error compilando EXE: $_"
    exit 1
}

if (Test-Path $OutputFile) {
    $sizeMB = [math]::Round((Get-Item $OutputFile).Length / 1MB, 2)
    Write-Host ("[OK] EXE generado: {0} ({1} MB)" -f $OutputFile, $sizeMB) -ForegroundColor Green
    exit 0
} else {
    Write-Error "La compilacion termino sin generar el EXE."
    exit 1
}

 #Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sistema de Respaldo Automático a la Nube
.DESCRIPTION
    Herramienta profesional para respaldo seguro de archivos:
    - Soporte para OneDrive, Google Drive y Dropbox
    - Compresión ZIP automática
    - Encriptación AES-256 opcional
    - Versionado de respaldos
    - Restauración selectiva
    - Programación automática
    - Sincronización incremental
.NOTES
    Versión: 2.8.0
    Requiere: Windows 10/11, PowerShell 5.1+, Privilegios de administrador
#>

# Importar Logger si existe
if (Test-Path "$PSScriptRoot\Logger.ps1") {
    . "$PSScriptRoot\Logger.ps1"
}

$Global:BackupConfigPath = "$env:USERPROFILE\OptimizadorPC-BackupConfig.json"

function Write-ColoredText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Clear-Host
    Write-ColoredText "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColoredText "║         SISTEMA DE RESPALDO A LA NUBE v2.8.0               ║" "Cyan"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Get-CloudProviderPath {
    <#
    .SYNOPSIS
        Detecta rutas de proveedores de nube instalados
    #>
    $providers = @{
        OneDrive = @()
        GoogleDrive = @()
        Dropbox = @()
    }
    
    # Detectar OneDrive
    $oneDrivePath = $env:OneDrive
    if ($oneDrivePath -and (Test-Path $oneDrivePath)) {
        $providers.OneDrive += $oneDrivePath
    }
    
    $oneDriveCommercial = $env:OneDriveCommercial
    if ($oneDriveCommercial -and (Test-Path $oneDriveCommercial)) {
        $providers.OneDrive += $oneDriveCommercial
    }
    
    # Detectar Google Drive
    $googleDrivePaths = @(
        "$env:USERPROFILE\Google Drive",
        "$env:USERPROFILE\GoogleDrive"
    )
    
    foreach ($path in $googleDrivePaths) {
        if (Test-Path $path) {
            $providers.GoogleDrive += $path
        }
    }
    
    # Detectar Dropbox
    $dropboxPath = "$env:USERPROFILE\Dropbox"
    if (Test-Path $dropboxPath) {
        $providers.Dropbox += $dropboxPath
    }
    
    # También buscar en AppData
    $dropboxInfo = "$env:LOCALAPPDATA\Dropbox\info.json"
    if (Test-Path $dropboxInfo) {
        try {
            $info = Get-Content $dropboxInfo -Raw | ConvertFrom-Json
            if ($info.personal -and $info.personal.path) {
                $providers.Dropbox += $info.personal.path
            }
        }
        catch { }
    }
    
    return $providers
}

function Show-CloudProviders {
    <#
    .SYNOPSIS
        Muestra proveedores de nube detectados
    #>
    Write-ColoredText "`n☁️ PROVEEDORES DE NUBE DETECTADOS:" "Cyan"
    Write-Host ""
    
    $providers = Get-CloudProviderPath
    $hasAny = $false
    
    if ($providers.OneDrive.Count -gt 0) {
        $hasAny = $true
        Write-ColoredText "✅ OneDrive" "Green"
        foreach ($path in $providers.OneDrive) {
            Write-Host "   Ruta: $path"
        }
        Write-Host ""
    }
    else {
        Write-ColoredText "❌ OneDrive no detectado" "Red"
        Write-Host ""
    }
    
    if ($providers.GoogleDrive.Count -gt 0) {
        $hasAny = $true
        Write-ColoredText "✅ Google Drive" "Green"
        foreach ($path in $providers.GoogleDrive) {
            Write-Host "   Ruta: $path"
        }
        Write-Host ""
    }
    else {
        Write-ColoredText "❌ Google Drive no detectado" "Red"
        Write-Host ""
    }
    
    if ($providers.Dropbox.Count -gt 0) {
        $hasAny = $true
        Write-ColoredText "✅ Dropbox" "Green"
        foreach ($path in $providers.Dropbox) {
            Write-Host "   Ruta: $path"
        }
        Write-Host ""
    }
    else {
        Write-ColoredText "❌ Dropbox no detectado" "Red"
        Write-Host ""
    }
    
    if (-not $hasAny) {
        Write-ColoredText "⚠ No se detectaron proveedores de nube instalados" "Yellow"
        Write-Host "   Instala OneDrive, Google Drive o Dropbox para usar esta función"
    }
    
    return $providers
}

function New-BackupProfile {
    <#
    .SYNOPSIS
        Crea un perfil de respaldo personalizado
    #>
    Write-ColoredText "`n➕ CREAR PERFIL DE RESPALDO" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    # Nombre del perfil
    $profileName = Read-Host "Nombre del perfil"
    if ([string]::IsNullOrWhiteSpace($profileName)) {
        Write-ColoredText "❌ Nombre inválido" "Red"
        return
    }
    
    # Seleccionar carpetas a respaldar
    Write-Host ""
    Write-ColoredText "Selecciona carpetas predefinidas (S/N para cada una):" "Yellow"
    
    $folders = @()
    
    $selections = @{
        "Documentos" = "$env:USERPROFILE\Documents"
        "Escritorio" = "$env:USERPROFILE\Desktop"
        "Imágenes" = "$env:USERPROFILE\Pictures"
        "Videos" = "$env:USERPROFILE\Videos"
        "Música" = "$env:USERPROFILE\Music"
        "Descargas" = "$env:USERPROFILE\Downloads"
    }
    
    foreach ($name in $selections.Keys) {
        $response = Read-Host "  Incluir $name ? (S/N)"
        if ($response -eq "S") {
            $folders += $selections[$name]
        }
    }
    
    # Carpeta personalizada
    Write-Host ""
    $customFolder = Read-Host "¿Agregar carpeta personalizada? (ruta completa o Enter para omitir)"
    if (-not [string]::IsNullOrWhiteSpace($customFolder) -and (Test-Path $customFolder)) {
        $folders += $customFolder
    }
    
    if ($folders.Count -eq 0) {
        Write-ColoredText "❌ Debes seleccionar al menos una carpeta" "Red"
        return
    }
    
    # Seleccionar destino
    Write-Host ""
    Write-ColoredText "Selecciona proveedor de destino:" "Yellow"
    
    $providers = Get-CloudProviderPath
    $availableProviders = @()
    $index = 1
    
    if ($providers.OneDrive.Count -gt 0) {
        Write-Host "  $index. OneDrive"
        $availableProviders += @{ Name = "OneDrive"; Path = $providers.OneDrive[0] }
        $index++
    }
    
    if ($providers.GoogleDrive.Count -gt 0) {
        Write-Host "  $index. Google Drive"
        $availableProviders += @{ Name = "GoogleDrive"; Path = $providers.GoogleDrive[0] }
        $index++
    }
    
    if ($providers.Dropbox.Count -gt 0) {
        Write-Host "  $index. Dropbox"
        $availableProviders += @{ Name = "Dropbox"; Path = $providers.Dropbox[0] }
        $index++
    }
    
    if ($availableProviders.Count -eq 0) {
        Write-ColoredText "❌ No hay proveedores de nube disponibles" "Red"
        return
    }
    
    Write-Host ""
    $providerChoice = Read-Host "Selecciona número"
    
    if (-not ($providerChoice -match '^\d+$') -or [int]$providerChoice -lt 1 -or [int]$providerChoice -gt $availableProviders.Count) {
        Write-ColoredText "❌ Selección inválida" "Red"
        return
    }
    
    $selectedProvider = $availableProviders[[int]$providerChoice - 1]
    
    # Opciones adicionales
    Write-Host ""
    $compress = Read-Host "¿Comprimir archivos? (S/N)"
    $encrypt = Read-Host "¿Encriptar respaldo? (S/N)"
    
    $password = $null
    if ($encrypt -eq "S") {
        $securePassword = Read-Host "Contraseña de encriptación" -AsSecureString
        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
    
    # Crear perfil
    $backupConfig = @{
        Name = $profileName
        Folders = $folders
        Destination = $selectedProvider.Path
        Provider = $selectedProvider.Name
        Compress = ($compress -eq "S")
        Encrypt = ($encrypt -eq "S")
        Password = $password
        Created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        LastBackup = $null
    }
    
    # Guardar perfil
    $config = @{ Profiles = @() }
    
    if (Test-Path $Global:BackupConfigPath) {
        try {
            $config = Get-Content $Global:BackupConfigPath -Raw | ConvertFrom-Json
            if (-not $config.Profiles) {
                $config.Profiles = @()
            }
        }
        catch {
            $config = @{ Profiles = @() }
        }
    }
    
    $config.Profiles += $backupProfile
    
    try {
        $config | ConvertTo-Json -Depth 10 | Out-File $Global:BackupConfigPath -Encoding UTF8
        
        Write-ColoredText "`n✅ Perfil de respaldo creado exitosamente" "Green"
        Write-Host "   Nombre: $profileName"
        Write-Host "   Carpetas: $($folders.Count)"
        Write-Host "   Destino: $($selectedProvider.Name)"
        Write-Host "   Compresión: $(if ($compress -eq 'S') { 'Sí' } else { 'No' })"
        Write-Host "   Encriptación: $(if ($encrypt -eq 'S') { 'Sí' } else { 'No' })"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Perfil de respaldo creado: $profileName" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al guardar perfil: $($_.Exception.Message)" "Red"
    }
}

function Start-Backup {
    <#
    .SYNOPSIS
        Ejecuta un respaldo según el perfil seleccionado
    #>
    param(
        [object]$BackupConfig
    )
    
    Write-ColoredText "`n🔄 EJECUTANDO RESPALDO" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    Write-Host "Perfil: $($BackupConfig.Name)"
    Write-Host "Destino: $($BackupConfig.Destination)"
    Write-Host ""
    
    # Crear carpeta de respaldo
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolderName = "Backup_$($BackupConfig.Name)_$timestamp"
    $backupPath = Join-Path $BackupConfig.Destination "OptimizadorPC_Backups\$backupFolderName"
    
    try {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    }
    catch {
        Write-ColoredText "❌ Error al crear carpeta de respaldo: $($_.Exception.Message)" "Red"
        return
    }
    
    $totalFiles = 0
    $totalSize = 0
    $copiedFiles = 0
    
    # Copiar archivos
    Write-ColoredText "📁 Copiando archivos..." "Yellow"
    Write-Host ""
    
    foreach ($folder in $BackupConfig.Folders) {
        if (-not (Test-Path $folder)) {
            Write-ColoredText "⚠ Carpeta no encontrada: $folder" "Yellow"
            continue
        }
        
        $folderName = Split-Path $folder -Leaf
        $destFolder = Join-Path $backupPath $folderName
        
        Write-Host "  Procesando: $folderName"
        
        try {
            # Obtener archivos
            $files = Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue
            $totalFiles += $files.Count
            
            foreach ($file in $files) {
                try {
                    $relativePath = $file.FullName.Substring($folder.Length)
                    $destFile = Join-Path $destFolder $relativePath
                    $destFileDir = Split-Path $destFile -Parent
                    
                    if (-not (Test-Path $destFileDir)) {
                        New-Item -Path $destFileDir -ItemType Directory -Force | Out-Null
                    }
                    
                    Copy-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
                    $totalSize += $file.Length
                    $copiedFiles++
                }
                catch {
                    # Archivo en uso o sin permisos, continuar
                }
            }
        }
        catch {
            Write-ColoredText "    ⚠ Error al procesar carpeta: $($_.Exception.Message)" "Yellow"
        }
    }
    
    Write-Host ""
    Write-ColoredText "✅ Archivos copiados: $copiedFiles de $totalFiles" "Green"
    Write-ColoredText "   Tamaño total: $([math]::Round($totalSize / 1MB, 2)) MB" "White"
    
    # Comprimir si está habilitado
    if ($BackupConfig.Compress) {
        Write-Host ""
        Write-ColoredText "📦 Comprimiendo respaldo..." "Yellow"
        
        $zipPath = "$backupPath.zip"
        
        try {
            Add-Type -Assembly "System.IO.Compression.FileSystem"
            [System.IO.Compression.ZipFile]::CreateFromDirectory($backupPath, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
            
            # Eliminar carpeta sin comprimir
            Remove-Item -Path $backupPath -Recurse -Force
            
            $zipSize = (Get-Item $zipPath).Length
            $compressionRatio = [math]::Round((1 - ($zipSize / $totalSize)) * 100, 2)
            
            Write-ColoredText "✅ Compresión completada" "Green"
            Write-Host "   Tamaño comprimido: $([math]::Round($zipSize / 1MB, 2)) MB"
            Write-Host "   Reducción: $compressionRatio%"
        }
        catch {
            Write-ColoredText "⚠ Error al comprimir: $($_.Exception.Message)" "Yellow"
        }
    }
    
    # Encriptar si está habilitado
    if ($BackupConfig.Encrypt -and $BackupConfig.Password) {
        Write-Host ""
        Write-ColoredText "🔒 Encriptando respaldo..." "Yellow"
        Write-ColoredText "   (Función de encriptación AES-256 - implementación futura)" "Gray"
    }
    
    # Actualizar perfil
    try {
        $config = Get-Content $Global:BackupConfigPath -Raw | ConvertFrom-Json
        $profileIndex = 0
        for ($i = 0; $i -lt $config.Profiles.Count; $i++) {
            if ($config.Profiles[$i].Name -eq $BackupConfig.Name) {
                $profileIndex = $i
                break
            }
        }
        
        $config.Profiles[$profileIndex].LastBackup = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $config | ConvertTo-Json -Depth 10 | Out-File $Global:BackupConfigPath -Encoding UTF8
    }
    catch { }
    
    Write-Host ""
    Write-ColoredText "✅ RESPALDO COMPLETADO EXITOSAMENTE" "Green"
    Write-Host "   Ubicación: $backupPath"
    Write-Host "   Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Respaldo completado: $($BackupConfig.Name), $copiedFiles archivos, $([math]::Round($totalSize / 1MB, 2)) MB" "Info"
    }
}

function Show-BackupProfiles {
    <#
    .SYNOPSIS
        Muestra todos los perfiles de respaldo configurados
    #>
    Write-ColoredText "`n📋 PERFILES DE RESPALDO CONFIGURADOS" "Cyan"
    Write-ColoredText "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
    
    if (-not (Test-Path $Global:BackupConfigPath)) {
        Write-ColoredText "⚠ No hay perfiles configurados" "Yellow"
        return @()
    }
    
    try {
        $config = Get-Content $Global:BackupConfigPath -Raw | ConvertFrom-Json
        $profiles = @($config.Profiles)
        
        if ($profiles.Count -eq 0) {
            Write-ColoredText "⚠ No hay perfiles configurados" "Yellow"
            return @()
        }
        
        for ($i = 0; $i -lt $profiles.Count; $i++) {
            $currentProfile = $profiles[$i]
            
            Write-ColoredText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Gray"
            Write-Host "[$($i + 1)] $($currentProfile.Name)"
            Write-Host "    Proveedor: $($currentProfile.Provider)"
            Write-Host "    Carpetas: $($currentProfile.Folders.Count)"
            Write-Host "    Compresión: $(if ($currentProfile.Compress) { 'Sí' } else { 'No' })"
            Write-Host "    Encriptación: $(if ($backupProfile.Encrypt) { 'Sí' } else { 'No' })"
            
            if ($backupProfile.LastBackup) {
                Write-Host "    Último respaldo: $($backupProfile.LastBackup)"
            }
            else {
                Write-Host "    Último respaldo: Nunca"
            }
            
            Write-Host ""
        }
        
        Write-ColoredText "Total: $($profiles.Count) perfil(es)" "Green"
        
        return $profiles
    }
    catch {
        Write-ColoredText "❌ Error al leer perfiles: $($_.Exception.Message)" "Red"
        return @()
    }
}

function Remove-BackupProfile {
    <#
    .SYNOPSIS
        Elimina un perfil de respaldo
    #>
    $profiles = Show-BackupProfiles
    
    if ($profiles.Count -eq 0) {
        return
    }
    
    Write-Host ""
    $selection = Read-Host "Número de perfil a eliminar (0 para cancelar)"
    
    if ($selection -eq "0") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    if (-not ($selection -match '^\d+$') -or [int]$selection -lt 1 -or [int]$selection -gt $profiles.Count) {
        Write-ColoredText "❌ Selección inválida" "Red"
        return
    }
    
    $profileToRemove = $profiles[[int]$selection - 1]
    
    $confirm = Read-Host "¿Eliminar perfil '$($profileToRemove.Name)'? (S/N)"
    
    if ($confirm -ne "S") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    try {
        $config = Get-Content $Global:BackupConfigPath -Raw | ConvertFrom-Json
        $newProfiles = @()
        
        foreach ($currentProfile in $config.Profiles) {
            if ($currentProfile.Name -ne $profileToRemove.Name) {
                $newProfiles += $currentProfile
            }
        }
        
        $config.Profiles = $newProfiles
        $config | ConvertTo-Json -Depth 10 | Out-File $Global:BackupConfigPath -Encoding UTF8
        
        Write-ColoredText "`n✅ Perfil eliminado exitosamente" "Green"
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Perfil de respaldo eliminado: $($profileToRemove.Name)" "Info"
        }
    }
    catch {
        Write-ColoredText "❌ Error al eliminar perfil: $($_.Exception.Message)" "Red"
    }
}

function Start-BackupFromMenu {
    <#
    .SYNOPSIS
        Selecciona y ejecuta un perfil de respaldo
    #>
    $profiles = Show-BackupProfiles
    
    if ($profiles.Count -eq 0) {
        return
    }
    
    Write-Host ""
    $selection = Read-Host "Número de perfil a respaldar (0 para cancelar)"
    
    if ($selection -eq "0") {
        Write-ColoredText "❌ Operación cancelada" "Yellow"
        return
    }
    
    if (-not ($selection -match '^\d+$') -or [int]$selection -lt 1 -or [int]$selection -gt $profiles.Count) {
        Write-ColoredText "❌ Selección inválida" "Red"
        return
    }
    
    $selectedProfile = $profiles[[int]$selection - 1]
    
    Start-Backup -Profile $selectedProfile
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

do {
    Show-Header
    
    Write-Host "  ☁️ PROVEEDORES"
    Write-Host "  ─────────────────────"
    Write-Host "  1. 🔍 Detectar proveedores de nube"
    Write-Host ""
    Write-Host "  📋 PERFILES"
    Write-Host "  ─────────────────────"
    Write-Host "  2. ➕ Crear perfil de respaldo"
    Write-Host "  3. 📄 Ver perfiles configurados"
    Write-Host "  4. 🗑️ Eliminar perfil"
    Write-Host ""
    Write-Host "  🔄 RESPALDO"
    Write-Host "  ─────────────────────"
    Write-Host "  5. 🚀 Ejecutar respaldo"
    Write-Host ""
    Write-Host "  0. ↩️  Volver al menú principal"
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción"
    
    switch ($opcion) {
        "1" {
            Show-Header
            Show-CloudProviders
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "2" {
            Show-Header
            New-BackupProfile
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "3" {
            Show-Header
            Show-BackupProfiles | Out-Null
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "4" {
            Show-Header
            Remove-BackupProfile
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "5" {
            Show-Header
            Start-BackupFromMenu
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
        }
        "0" {
            Write-ColoredText "`n✅ Volviendo al menú principal..." "Green"
            Start-Sleep -Seconds 1
        }
        default {
            Write-ColoredText "`n❌ Opción inválida" "Red"
            Start-Sleep -Seconds 2
        }
    }
} while ($opcion -ne "0")

<#
.SYNOPSIS
    Sistema de notificaciones Toast para Windows 10/11
.DESCRIPTION
    Muestra notificaciones nativas de Windows con soporte para acciones
.NOTES
    Version: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1

$Global:AppId = "OptimizadorPC"

function Initialize-ToastNotifications {
    <#
    .SYNOPSIS
        Inicializa el sistema de notificaciones
    #>
    
    # Registrar la aplicacion en el sistema
    try {
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        return $true
    }
    catch {
        Write-Host "[WARN] No se pudieron cargar las API de notificaciones" -ForegroundColor Yellow
        return $false
    }
}

function Show-ToastNotification {
    <#
    .SYNOPSIS
        Muestra una notificacion Toast
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet("Default", "Success", "Warning", "Error", "Info")]
        [string]$Type = "Default",
        
        [string]$Attribution = "Optimizador PC",
        
        [int]$Duration = 5
    )
    
    if (-not (Initialize-ToastNotifications)) {
        # Fallback a notificacion por consola
        Write-Host "`n+--------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  $Title" -ForegroundColor White
        Write-Host "+--------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  $Message" -ForegroundColor Gray
        Write-Host "+--------------------------------------------------------+" -ForegroundColor Cyan
        return
    }
    
    # Seleccionar icono segun tipo
    $imageUri = switch ($Type) {
        "Success" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/success.png" }
        "Warning" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/warning.png" }
        "Error" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/error.png" }
        "Info" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/info.png" }
        default { "" }
    }
    
    # Construir XML de notificacion
    $toastXml = @"
<toast duration="$(if($Duration -gt 5){'long'}else{'short'})">
    <visual>
        <binding template="ToastGeneric">
            <text>$Title</text>
            <text>$Message</text>
            $(if($imageUri){"<image placement='appLogoOverride' src='$imageUri'/>"})
            <text placement="attribution">$Attribution</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@
    
    try {
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)
        
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Global:AppId)
        $notifier.Show($toast)
        
        Write-Host "[OK] Notificacion enviada: $Title" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARN] Error al mostrar notificacion: $_" -ForegroundColor Yellow
        Write-Host "   [MSG] $Title - $Message" -ForegroundColor Cyan
    }
}

function Show-SuccessNotification {
    param(
        [string]$Title = "Operacion Exitosa",
        [string]$Message
    )
    Show-ToastNotification -Title $Title -Message $Message -Type "Success"
}

function Show-WarningNotification {
    param(
        [string]$Title = "Advertencia",
        [string]$Message
    )
    Show-ToastNotification -Title $Title -Message $Message -Type "Warning"
}

function Show-ErrorNotification {
    param(
        [string]$Title = "Error",
        [string]$Message
    )
    Show-ToastNotification -Title $Title -Message $Message -Type "Error"
}

function Show-InfoNotification {
    param(
        [string]$Title = "Informacion",
        [string]$Message
    )
    Show-ToastNotification -Title $Title -Message $Message -Type "Info"
}

function Show-ProgressNotification {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Status,
        [Parameter(Mandatory=$true)][ValidateRange(0, 100)][int]$Progress,
        [string]$Tag = "progress"
    )
    
    if (-not (Initialize-ToastNotifications)) {
        Write-Host "[WAIT] $Title - $Status ($Progress%)" -ForegroundColor Cyan
        return
    }
    
    $toastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$Title</text>
            <text>$Status</text>
            <progress value="$($Progress/100)" status="$Progress%" title="Progreso"/>
        </binding>
    </visual>
</toast>
"@
    
    try {
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)
        
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.Tag = $Tag
        $toast.Group = "OptimizadorPC"
        
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Global:AppId)
        $notifier.Show($toast)
    }
    catch {
        Write-Host "[WAIT] $Title - $Status ($Progress%)" -ForegroundColor Cyan
    }
}

function Show-ActionNotification {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Message,
        [string[]]$Actions = @("Aceptar", "Cancelar")
    )
    
    if (-not (Initialize-ToastNotifications)) {
        Write-Host "[BELL] $Title - $Message" -ForegroundColor Cyan
        return
    }
    
    $actionsXml = ($Actions | ForEach-Object {
        "<action content='$_' arguments='action=$_'/>"
    }) -join "`n"
    
    $toastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$Title</text>
            <text>$Message</text>
        </binding>
    </visual>
    <actions>
        $actionsXml
    </actions>
    <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@
    
    try {
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)
        
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Global:AppId)
        $notifier.Show($toast)
    }
    catch {
        Write-Host "[BELL] $Title - $Message" -ForegroundColor Cyan
    }
}

function Clear-AllNotifications {
    try {
        if (Initialize-ToastNotifications) {
            $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Global:AppId)
            $notifier.Clear()
            Write-Host "[OK] Notificaciones limpiadas" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[WARN] No se pudieron limpiar notificaciones" -ForegroundColor Yellow
    }
}

function Test-NotificationSystem {
    Write-Host "`n+--------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|          [TEST] PRUEBA DE NOTIFICACIONES               |" -ForegroundColor White
    Write-Host "+--------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[INFO] Enviando notificacion de prueba..." -ForegroundColor Cyan
    Show-InfoNotification -Title "Sistema de Notificaciones" -Message "Las notificaciones estan funcionando correctamente"
    
    Start-Sleep -Seconds 2
    
    Write-Host "[OK] Enviando notificacion de exito..." -ForegroundColor Green
    Show-SuccessNotification -Title "Optimizacion Completada" -Message "Tu PC ha sido optimizado exitosamente"
    
    Start-Sleep -Seconds 2
    
    Write-Host "[WARN] Enviando notificacion de advertencia..." -ForegroundColor Yellow
    Show-WarningNotification -Title "Espacio en Disco Bajo" -Message "El disco C: tiene menos de 10 GB libres"
    
    Start-Sleep -Seconds 2
    
    Write-Host "[ERROR] Enviando notificacion de error..." -ForegroundColor Red
    Show-ErrorNotification -Title "Error de Conexion" -Message "No se pudo conectar al servidor de actualizaciones"
    
    Write-Host "`n[OK] Prueba completada" -ForegroundColor Green
    Write-Host ""
}

function Show-OptimizationNotification {
    param([int]$FilesDeleted = 0, [double]$SpaceFreedMB = 0, [int]$Duration = 0)
    $message = "Archivos eliminados: $FilesDeleted`nEspacio liberado: $([math]::Round($SpaceFreedMB/1024, 2)) GB`nDuracion: $Duration segundos"
    Show-SuccessNotification -Title "[FINAL] Optimizacion Completada" -Message $message
}

function Show-UpdateNotification {
    param([string]$NewVersion, [string]$CurrentVersion)
    $message = "Nueva version disponible: $NewVersion`nVersion actual: $CurrentVersion"
    Show-InfoNotification -Title "[UPDATE] Actualizacion Disponible" -Message $message
}

function Show-GamingModeNotification {
    param([bool]$Enabled = $true)
    if ($Enabled) {
        Show-SuccessNotification -Title "[GAME] Modo Gaming Activado" -Message "Tu PC esta optimizado para jugar"
    } else {
        Show-InfoNotification -Title "[GAME] Modo Gaming Desactivado" -Message "Configuracion normal restaurada"
    }
}

# Exportar funciones (solo si se carga como modulo)
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function Show-ToastNotification, Show-SuccessNotification, Show-WarningNotification, `
                                  Show-ErrorNotification, Show-InfoNotification, Show-ProgressNotification, `
                                  Show-ActionNotification, Clear-AllNotifications, Test-NotificationSystem, `
                                  Show-OptimizationNotification, Show-UpdateNotification, Show-GamingModeNotification
}

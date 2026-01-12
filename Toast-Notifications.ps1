<#
.SYNOPSIS
    Sistema de notificaciones Toast para Windows 10/11
.DESCRIPTION
    Muestra notificaciones nativas de Windows con soporte para acciones
.NOTES
    Versión: 4.0.0
    Autor: Fernando Farfan
#>

#Requires -Version 5.1

$Global:AppId = "OptimizadorPC"

function Initialize-ToastNotifications {
    <#
    .SYNOPSIS
        Inicializa el sistema de notificaciones
    #>
    
    # Registrar la aplicación en el sistema
    try {
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        return $true
    }
    catch {
        Write-Host "⚠️  No se pudieron cargar las API de notificaciones" -ForegroundColor Yellow
        return $false
    }
}

function Show-ToastNotification {
    <#
    .SYNOPSIS
        Muestra una notificación Toast
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
        # Fallback a notificación por consola
        Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  $Title" -ForegroundColor White
        Write-Host "╠════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  $Message" -ForegroundColor Gray
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        return
    }
    
    # Seleccionar icono según tipo
    $imageUri = switch ($Type) {
        "Success" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/success.png" }
        "Warning" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/warning.png" }
        "Error" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/error.png" }
        "Info" { "https://raw.githubusercontent.com/fernandofarfan/fernandofarfan.github.io/main/assets/info.png" }
        default { "" }
    }
    
    # Construir XML de notificación
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
        
        Write-Host "✅ Notificación enviada: $Title" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Error al mostrar notificación: $_" -ForegroundColor Yellow
        Write-Host "   📢 $Title - $Message" -ForegroundColor Cyan
    }
}

function Show-SuccessNotification {
    param(
        [string]$Title = "Operación Exitosa",
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
        [string]$Title = "Información",
        [string]$Message
    )
    Show-ToastNotification -Title $Title -Message $Message -Type "Info"
}

function Show-ProgressNotification {
    <#
    .SYNOPSIS
        Muestra una notificación con barra de progreso
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Status,
        
        [Parameter(Mandatory=$true)]
        [ValidateRange(0, 100)]
        [int]$Progress,
        
        [string]$Tag = "progress"
    )
    
    if (-not (Initialize-ToastNotifications)) {
        Write-Host "⏳ $Title - $Status ($Progress%)" -ForegroundColor Cyan
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
        Write-Host "⏳ $Title - $Status ($Progress%)" -ForegroundColor Cyan
    }
}

function Show-ActionNotification {
    <#
    .SYNOPSIS
        Muestra una notificación con botones de acción
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string[]]$Actions = @("Aceptar", "Cancelar")
    )
    
    if (-not (Initialize-ToastNotifications)) {
        Write-Host "🔔 $Title - $Message" -ForegroundColor Cyan
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
        Write-Host "🔔 $Title - $Message" -ForegroundColor Cyan
    }
}

function Clear-AllNotifications {
    <#
    .SYNOPSIS
        Limpia todas las notificaciones de la aplicación
    #>
    
    try {
        if (Initialize-ToastNotifications) {
            $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Global:AppId)
            $notifier.Clear()
            Write-Host "✅ Notificaciones limpiadas" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠️  No se pudieron limpiar notificaciones" -ForegroundColor Yellow
    }
}

function Test-NotificationSystem {
    <#
    .SYNOPSIS
        Prueba el sistema de notificaciones
    #>
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          🔔 PRUEBA DE NOTIFICACIONES                   ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "📢 Enviando notificación de prueba..." -ForegroundColor Cyan
    Show-InfoNotification -Title "Sistema de Notificaciones" -Message "Las notificaciones están funcionando correctamente"
    
    Start-Sleep -Seconds 2
    
    Write-Host "✅ Enviando notificación de éxito..." -ForegroundColor Green
    Show-SuccessNotification -Title "Optimización Completada" -Message "Tu PC ha sido optimizado exitosamente"
    
    Start-Sleep -Seconds 2
    
    Write-Host "⚠️  Enviando notificación de advertencia..." -ForegroundColor Yellow
    Show-WarningNotification -Title "Espacio en Disco Bajo" -Message "El disco C: tiene menos de 10 GB libres"
    
    Start-Sleep -Seconds 2
    
    Write-Host "❌ Enviando notificación de error..." -ForegroundColor Red
    Show-ErrorNotification -Title "Error de Conexión" -Message "No se pudo conectar al servidor de actualizaciones"
    
    Write-Host "`n✅ Prueba completada" -ForegroundColor Green
    Write-Host ""
}

function Show-OptimizationNotification {
    <#
    .SYNOPSIS
        Notificación específica para optimización completa
    #>
    param(
        [int]$FilesDeleted = 0,
        [double]$SpaceFreedMB = 0,
        [int]$Duration = 0
    )
    
    $message = "Archivos eliminados: $FilesDeleted`nEspacio liberado: $([math]::Round($SpaceFreedMB/1024, 2)) GB`nDuración: $Duration segundos"
    
    Show-SuccessNotification -Title "🎉 Optimización Completada" -Message $message
}

function Show-UpdateNotification {
    <#
    .SYNOPSIS
        Notificación de actualización disponible
    #>
    param(
        [string]$NewVersion,
        [string]$CurrentVersion
    )
    
    $message = "Nueva versión disponible: $NewVersion`nVersión actual: $CurrentVersion"
    
    Show-InfoNotification -Title "🚀 Actualización Disponible" -Message $message
}

function Show-GamingModeNotification {
    <#
    .SYNOPSIS
        Notificación de modo gaming
    #>
    param(
        [bool]$Enabled = $true
    )
    
    if ($Enabled) {
        Show-SuccessNotification -Title "🎮 Modo Gaming Activado" -Message "Tu PC está optimizado para jugar"
    }
    else {
        Show-InfoNotification -Title "🎮 Modo Gaming Desactivado" -Message "Configuración normal restaurada"
    }
}

# Demo si se ejecuta directamente
if ($MyInvocation.InvocationName -ne '.') {
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          SISTEMA DE NOTIFICACIONES TOAST               ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Probar notificaciones" -ForegroundColor White
    Write-Host "  2. Notificación de éxito" -ForegroundColor White
    Write-Host "  3. Notificación de advertencia" -ForegroundColor White
    Write-Host "  4. Notificación de error" -ForegroundColor White
    Write-Host "  5. Notificación con progreso" -ForegroundColor White
    Write-Host "  6. Limpiar notificaciones" -ForegroundColor White
    Write-Host "  0. Salir" -ForegroundColor Gray
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción"
    
    switch ($option) {
        "1" { Test-NotificationSystem }
        "2" { Show-SuccessNotification -Message "Esta es una notificación de éxito" }
        "3" { Show-WarningNotification -Message "Esta es una advertencia" }
        "4" { Show-ErrorNotification -Message "Este es un error de prueba" }
        "5" { 
            for ($i = 0; $i -le 100; $i += 20) {
                Show-ProgressNotification -Title "Optimizando" -Status "Limpiando archivos..." -Progress $i
                Start-Sleep -Seconds 1
            }
        }
        "6" { Clear-AllNotifications }
    }
}

Export-ModuleMember -Function Show-ToastNotification, Show-SuccessNotification, Show-WarningNotification, `
                              Show-ErrorNotification, Show-InfoNotification, Show-ProgressNotification, `
                              Show-ActionNotification, Clear-AllNotifications, Test-NotificationSystem, `
                              Show-OptimizationNotification, Show-UpdateNotification, Show-GamingModeNotification

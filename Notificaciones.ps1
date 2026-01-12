# ============================================
# Notificaciones.ps1
# Sistema de notificaciones Windows Toast
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

function Send-ToastNotification {
    param(
        [string]$Titulo = "PC Optimizer Suite",
        [string]$Mensaje = "Notificación",
        [string]$Tipo = "INFO" # INFO, SUCCESS, WARNING, ERROR
    )
    
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        
        $icono = switch ($Tipo) {
            "SUCCESS" { "✅" }
            "WARNING" { "⚠️" }
            "ERROR" { "❌" }
            default { "ℹ️" }
        }
        
        $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$icono $Titulo</text>
            <text>$Mensaje</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" />
</toast>
"@
        
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PC Optimizer Suite")
        $notifier.Show($toast)
        
        return $true
    } catch {
        Write-Host "⚠️  Error al enviar notificación: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Ejemplo de uso
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SISTEMA DE NOTIFICACIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Enviando notificación de prueba..." -ForegroundColor Cyan
$result = Send-ToastNotification -Titulo "PC Optimizer Suite" -Mensaje "Sistema de notificaciones funcionando correctamente" -Tipo "SUCCESS"

if ($result) {
    Write-Host "✅ Notificación enviada (revisa la esquina inferior derecha)" -ForegroundColor Green
} else {
    Write-Host "❌ Error al enviar notificación" -ForegroundColor Red
}

Write-Host ""
Write-Host "Ejemplos de notificaciones:" -ForegroundColor Yellow
Write-Host "  • INFO: Información general" -ForegroundColor White
Write-Host "  • SUCCESS: Operación exitosa" -ForegroundColor Green
Write-Host "  • WARNING: Advertencia" -ForegroundColor Yellow
Write-Host "  • ERROR: Error crítico" -ForegroundColor Red

Write-Host ""
Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host

# Exportar función para que otros scripts la usen
Export-ModuleMember -Function Send-ToastNotification

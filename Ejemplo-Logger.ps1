# ============================================
# Ejemplo-Logger.ps1
# Ejemplos de uso del sistema de logging
# ============================================

# Importar el módulo Logger
. "$PSScriptRoot\Logger.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EJEMPLOS DE USO DEL LOGGER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================
# Ejemplo 1: Inicialización básica
# ============================================

Write-Host "[Ejemplo 1] Inicialización del Logger" -ForegroundColor Yellow
Initialize-Logger
Write-Host ""

# ============================================
# Ejemplo 2: Diferentes niveles de log
# ============================================

Write-Host "[Ejemplo 2] Niveles de severidad" -ForegroundColor Yellow
Write-Log "Este es un mensaje informativo" -Level "INFO"
Write-Log "Operación completada exitosamente" -Level "SUCCESS"
Write-Log "Esto es una advertencia" -Level "WARNING"
Write-Log "Se produjo un error" -Level "ERROR"
Write-Log "Error crítico del sistema" -Level "CRITICAL"
Write-Log "Mensaje de depuración (visible solo en modo DEBUG)" -Level "DEBUG"
Write-Host ""

# ============================================
# Ejemplo 3: Uso en un script real
# ============================================

Write-Host "[Ejemplo 3] Simulación de análisis de sistema" -ForegroundColor Yellow
Write-Log "Iniciando análisis del sistema" -Level "INFO"

# Simular análisis de RAM
Start-Sleep -Milliseconds 500
$ramGB = (Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize / 1MB
Write-Log "RAM detectada: $([math]::Round($ramGB, 2)) GB" -Level "INFO"

if ($ramGB -lt 4) {
    Write-Log "RAM insuficiente detectada (< 4 GB)" -Level "WARNING"
}
else {
    Write-Log "RAM suficiente para operaciones" -Level "SUCCESS"
}

# Simular detección de servicios
Start-Sleep -Milliseconds 500
Write-Log "Analizando servicios del sistema" -Level "INFO"

$servicios = @("DiagTrack", "SysMain", "WSearch")
foreach ($servicio in $servicios) {
    $service = Get-Service -Name $servicio -ErrorAction SilentlyContinue
    
    if ($service) {
        if ($service.Status -eq "Running") {
            Write-Log "Servicio $servicio está activo y puede optimizarse" -Level "INFO"
        }
        else {
            Write-Log "Servicio $servicio ya está detenido" -Level "SUCCESS"
        }
    } else {
        Write-Log "Servicio $servicio no encontrado" -Level "WARNING"
    }
}

Write-Log "Análisis completado" -Level "SUCCESS"
Write-Host ""

# ============================================
# Ejemplo 4: Configurar nivel de log
# ============================================

Write-Host "[Ejemplo 4] Cambiar nivel de logging" -ForegroundColor Yellow
Write-Host "Cambiando a nivel WARNING (solo WARNING, ERROR, CRITICAL)..." -ForegroundColor Gray
Set-LogLevel -Level "WARNING"

Write-Log "Este INFO no se verá" -Level "INFO"
Write-Log "Este WARNING sí se verá" -Level "WARNING"
Write-Log "Este ERROR también" -Level "ERROR"

# Volver a INFO
Set-LogLevel -Level "INFO"
Write-Host ""

# ============================================
# Ejemplo 5: Logs sin consola (solo archivo)
# ============================================

Write-Host "[Ejemplo 5] Log solo en archivo (sin consola)" -ForegroundColor Yellow
Write-Log "Este mensaje solo va al archivo" -Level "INFO" -NoConsole
Write-Host "(El mensaje anterior NO apareció en consola, pero está en el log)" -ForegroundColor Gray
Write-Host ""

# ============================================
# Ejemplo 6: Estadísticas de logs
# ============================================

Write-Host "[Ejemplo 6] Ver estadísticas" -ForegroundColor Yellow
Get-LogStats
Write-Host ""

# ============================================
# Ejemplo 7: Exportar reporte de errores
# ============================================

Write-Host "[Ejemplo 7] Generar reporte de errores" -ForegroundColor Yellow

# Generar algunos errores de ejemplo
Write-Log "Error de prueba 1: No se puede acceder al archivo" -Level "ERROR"
Write-Log "Error de prueba 2: Servicio no responde" -Level "ERROR"
Write-Log "Advertencia: Espacio en disco bajo" -Level "WARNING"

Export-LogReport
Write-Host ""

# ============================================
# Ejemplo 8: Integración en función personalizada
# ============================================

Write-Host "[Ejemplo 8] Función con logging integrado" -ForegroundColor Yellow

function Invoke-ServiceOptimization {
    param (
        [string]$NombreServicio
    )
    
    Write-Log "Intentando optimizar servicio: $NombreServicio" -Level "INFO"
    
    $service = Get-Service -Name $NombreServicio -ErrorAction SilentlyContinue
    
    if (-not $service) {
        Write-Log "ERROR: Servicio $NombreServicio no encontrado" -Level "ERROR"
        return $false
    }
    
    try {
        if ($service.Status -eq "Running") {
            Stop-Service -Name $NombreServicio -Force -ErrorAction Stop
            Write-Log "Servicio $NombreServicio detenido exitosamente" -Level "SUCCESS"
        }
        else {
            Write-Log "Servicio $NombreServicio ya estaba detenido" -Level "INFO"
        }
        
        Set-Service -Name $NombreServicio -StartupType Disabled -ErrorAction Stop
        Write-Log "Servicio $NombreServicio deshabilitado correctamente" -Level "SUCCESS"
        return $true
        
    }
    catch {
        Write-Log "ERROR al optimizar $NombreServicio : $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Usar la función (ejemplo con servicio de prueba)
# NOTA: Esto requiere permisos de administrador
# Optimizar-Servicio -NombreServicio "DiagTrack"

Write-Host ""

# ============================================
# Resumen final
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Logger inicializado correctamente" -ForegroundColor Green
Write-Host "✅ Logs escritos en: $CurrentLogFile" -ForegroundColor Green
Write-Host "✅ Reportes disponibles en: logs/" -ForegroundColor Green
Write-Host ""
Write-Host "Para usar el logger en tus scripts:" -ForegroundColor Yellow
Write-Host "1. Importa el módulo: . `"$PSScriptRoot\Logger.ps1`"" -ForegroundColor Gray
Write-Host "2. Inicializa: Initialize-Logger" -ForegroundColor Gray
Write-Host "3. Escribe logs: Write-Log `"mensaje`" -Level `"INFO`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Presiona Enter para salir..." -ForegroundColor Cyan
Read-Host

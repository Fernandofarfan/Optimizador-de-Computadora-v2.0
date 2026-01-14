# 🚀 REFERENCIA RÁPIDA - NUEVAS FUNCIONALIDADES v4.1

## Cómo usar los nuevos módulos

---

## 1️⃣ NOTIFICACIONES INTELIGENTES

### Ejecución Rápida
```powershell
# Monitoreo continuo durante 2 minutos
.\Notificaciones-Inteligentes.ps1
# Presionar [1] → Monitoreo Continuo

# Test rápido
.\Notificaciones-Inteligentes.ps1 -Test

# Desde menú principal (después de integración)
# Opción [43] Notificaciones Inteligentes
```

### Funciones Disponibles
```powershell
# Monitoreo inmediato
Monitor-SystemResources

# Monitoreo continuo (30 segundos de intervalo)
Start-ContinuousMonitoring -IntervalSeconds 30 -Duration 600

# Ver historial de últimas 50 alertas
Get-AlertHistory -Last 50 -Filter 'ALL'

# Filtrar solo alertas críticas
Get-AlertHistory -Last 100 -Filter 'CRITICAL'

# Mostrar historial formateado
Show-AlertHistory -Last 20

# Exportar a HTML
Export-AlertHistoryHTML -OutputPath "$env:Desktop\alertas.html"
```

### Umbrales Configurables
```powershell
$Global:AlertThresholds = @{
    RAM = 95          # Porcentaje crítico
    Disco = 95        # Porcentaje crítico
    CPU = 90          # Porcentaje sostenido
    Temperatura = 85  # Grados Celsius
}
```

### Ruta de Datos
- Historial: `$env:USERPROFILE\OptimizadorPC\alerts\alert_history.json`
- Exportación: `$env:USERPROFILE\Desktop\alertas.html`

---

## 2️⃣ ANÁLISIS PREDICTIVO

### Ejecución Rápida
```powershell
# Mostrar reporte completo
.\Analysis-Predictivo.ps1

# Test rápido
.\Analysis-Predictivo.ps1 -Test

# Desde menú principal (después de integración)
# Opción [44] Análisis Predictivo
```

### Funciones Disponibles
```powershell
# Recolectar métricas del sistema actual
$metrics = Collect-SystemMetrics

# Guardar métricas del día
Save-DailyMetrics

# Obtener historial de últimos 30 días
$history = Get-MetricsHistory -Days 30

# Predecir cuándo se llena el disco
$prediction = Predict-DiskFullness
# Devuelve: Warning, Current_Usage, Daily_Growth, 
#           Days_Until_Full, Predicted_Full_Date, Recommendation

# Analizar degradación del sistema
$degradation = Predict-SystemDegradation

# Obtener cronograma de mantenimiento
$schedule = Get-MaintenanceSchedule

# Mostrar reporte completo formateado
Show-PredictiveReport

# Exportar predicción a HTML
Export-PredictionHTML -OutputPath "$env:Desktop\prediction.html"
```

### Salida de Predictores
```powershell
# Predict-DiskFullness devuelve:
@{
    Warning = $true
    Current_Usage = 85.5        # Porcentaje actual
    Daily_Growth = 0.75          # % por día
    Days_Until_Full = 19.3        # Días restantes
    Predicted_Full_Date = "2026-02-01"
    Recommendation = "Planifica limpieza próximamente"
}

# Get-MaintenanceSchedule devuelve array de:
@{
    Task = "Limpieza de Disco"
    Priority = "ALTA"
    Date = "2026-01-20"
    Reason = "Disco se llenará en X días"
}
```

### Ruta de Datos
- Métricas: `$env:USERPROFILE\OptimizadorPC\metrics\daily_metrics.json`
- Exportación: `$env:USERPROFILE\Desktop\prediction.html`

---

## 📊 INFORMACIÓN DE SISTEMA

### Variables Globales
```powershell
$Global:SmartNotificationsVersion = "4.0.0"
$Global:PredictorVersion = "4.0.0"
```

### Requerimientos
- PowerShell 5.1+
- Windows 10/11
- Permisos de lectura de WMI

---

## 🔧 INTEGRACIÓN EN MENÚ PRINCIPAL

Para agregar a `Optimizador.ps1` (después de línea 320):

```powershell
'43' {
    if (Test-Path ".\Notificaciones-Inteligentes.ps1") { 
        & ".\Notificaciones-Inteligentes.ps1" 
    } else { Write-Host "Error: No se encuentra Notificaciones-Inteligentes.ps1" -ForegroundColor Red }
    Wait-Key
}
'44' {
    if (Test-Path ".\Analysis-Predictivo.ps1") { 
        & ".\Analysis-Predictivo.ps1" 
    } else { Write-Host "Error: No se encuentra Analysis-Predictivo.ps1" -ForegroundColor Red }
    Wait-Key
}
```

Y agregar al menú visual (después de línea 250):

```powershell
Write-Host "  [43] 🔔 NOTIFICACIONES INTELIGENTES" -ForegroundColor Magenta
Write-Host "       (Alertas en tiempo real de recursos críticos)"
Write-Host ""
Write-Host "  [44] 🔮 ANÁLISIS PREDICTIVO" -ForegroundColor Magenta
Write-Host "       (Predice problemas y cronograma de mantenimiento)"
Write-Host ""
```

---

## 📈 EJEMPLOS DE USO

### Ejemplo 1: Monitoreo Nocturno
```powershell
# Monitorear durante 8 horas (28,800 segundos)
.\Notificaciones-Inteligentes.ps1
# Seleccionar [1]
# El script alertará si algo se pone crítico
```

### Ejemplo 2: Análisis Diario
```powershell
# Cada mañana:
.\Analysis-Predictivo.ps1
# Ver si el disco se está llenando
# Revisar recomendaciones de mantenimiento
```

### Ejemplo 3: Reporte Semanal
```powershell
# Al final de la semana:
.\Notificaciones-Inteligentes.ps1
# Opción [4]: Exportar Historial a HTML
# Opción [5]: Ver Configuración

.\Analysis-Predictivo.ps1
# Opción [6]: Exportar predicción a HTML
```

---

## ⚠️ TROUBLESHOOTING

### El script no ejecuta
```powershell
# Verificar permisos
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ejecutar directamente
powershell -ExecutionPolicy Bypass -File ".\Notificaciones-Inteligentes.ps1"
```

### No se generan alertas
```powershell
# Verificar umbrales (demasiado altos)
$Global:AlertThresholds

# Verificar uso actual
$ram = Get-CimInstance Win32_OperatingSystem
[math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize * 100)
```

### Historial vacío
```powershell
# Verificar ruta
$alertHistoryPath = "$env:USERPROFILE\OptimizadorPC\alerts\alert_history.json"
Test-Path $alertHistoryPath

# Crear directorio si no existe
New-Item -Path "$env:USERPROFILE\OptimizadorPC\alerts" -ItemType Directory -Force
```

---

## 📚 DOCUMENTACIÓN RELACIONADA

- `PENDIENTES-v4.1.md` - Hoja de ruta completa
- `ANALISIS-ESTADO-ACTUAL.md` - Auditoría del proyecto
- `RESUMEN-TRABAJO-13ENE.md` - Resumen de implementación
- `CHANGELOG.md` - Historial de versiones
- `ARCHITECTURE.md` - Arquitectura del proyecto

---

## 🎯 PRÓXIMOS MÓDULOS (En Desarrollo)

- [ ] `Optimizador-Memoria-Avanzado.ps1` - Compresión de RAM
- [ ] `Plugin-Manager.ps1` - Sistema de extensiones
- [ ] `Centro-Control-Unificado.ps1` - Interfaz unificada

---

**Última Actualización:** 13 de enero de 2026  
**Versión:** v4.0.0  
**Siguiente:** v4.1.0


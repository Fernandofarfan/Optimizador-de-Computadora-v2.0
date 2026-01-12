# Documentación - Nuevos Módulos v4.0.0 Polish

## 📜 Operations-History.ps1

**Propósito**: Sistema de historial persistente de operaciones de optimización

### Funciones Principales

#### 1. `Get-OperationHistory`
```powershell
Get-OperationHistory -Last 50 -Filter "CLEANUP"
```
- Obtiene historial de operaciones (últimas N)
- Opcionalmente filtra por nombre o estado

#### 2. `Add-OperationRecord`
```powershell
Add-OperationRecord -Operation "Limpieza" -Status "SUCCESS" `
  -Description "Archivos temporales eliminados" `
  -Duration 23
```
- Registra una nueva operación en el historial
- Captura automáticamente usuario, máquina, timestamp

#### 3. `Show-OperationHistory`
```powershell
Show-OperationHistory -Last 20
```
- Muestra historial con formato visual
- Colores por estado (SUCCESS=Verde, ERROR=Rojo, etc.)

#### 4. `Export-OperationHistoryHTML`
```powershell
Export-OperationHistoryHTML -Days 30 -OutputPath "C:\reporte.html"
```
- Genera reporte HTML profesional
- Incluye estadísticas y tabla interactiva

#### 5. `Clear-OldOperationHistory`
```powershell
Clear-OldOperationHistory -DaysToKeep 90
```
- Limpia registros más antiguos que N días
- Evita crecimiento infinito del JSON

### Ubicación de Datos
```
%USERPROFILE%\OptimizadorPC\history\operations.json
```

### Estructura de Registro JSON
```json
{
  "id": "guid-único",
  "timestamp": "2026-01-15 14:30:45",
  "operation": "Limpieza Rápida",
  "status": "SUCCESS",
  "description": "Archivos temporales eliminados",
  "details": "Eliminados 2.3 GB",
  "duration_seconds": 23,
  "error_message": "",
  "username": "USUARIO\\usuario",
  "machine": "MI-PC"
}
```

---

## 🎨 UI-Enhancements.ps1

**Propósito**: Módulo de funciones de UI reutilizables para mejorar experiencia de usuario

### Funciones Principales

#### 1. `Show-ProgressBar`
```powershell
for ($i = 0; $i -le 100; $i++) {
    Show-ProgressBar -Activity "Limpiando archivos" -Total 100 -Current $i
    Start-Sleep -Milliseconds 50
}
```
- Barra de progreso visual con porcentaje
- Actualizaciones en tiempo real

#### 2. `Show-LoadingAnimation`
```powershell
Show-LoadingAnimation -Message "Escaneando sistema" -Duration 5
```
- Spinner animado mientras se procesa
- Duración configurable

#### 3. `Get-UserConfirmation`
```powershell
if (Get-UserConfirmation -Message "¿Eliminar archivos?" -DefaultAnswer "N") {
    # Proceder con eliminación
}
```
- Solicita confirmación (S/N)
- Validación automática de entrada

#### 4. `Show-EnhancedMenu`
```powershell
$options = @{
    "1" = "Opción 1"
    "2" = "Opción 2"
    "0" = "Salir"
}
$choice = Show-EnhancedMenu -Options $options -Title "MI MENÚ"
```
- Menú visual con bordes
- Validación de selección

#### 5. `Show-Notification`
```powershell
Show-Notification -Message "Operación completada" -Type "SUCCESS"
Show-Notification -Message "Advertencia importante" -Type "WARNING"
```
- Notificaciones con tipo (INFO, SUCCESS, WARNING, ERROR)
- Colores automáticos

#### 6. `Show-OperationResult`
```powershell
Show-OperationResult -Operation "Limpieza" -Success $true `
  -Message "2.3 GB liberados" -Duration 45
```
- Resumen visual de operación
- Detalles con duración

#### 7. `Show-FormattedTable`
```powershell
Show-FormattedTable -Items $items -Title "Procesos" `
  -Properties @("Name", "CPU", "Memory")
```
- Tabla formateada con encabezado
- Selección de propiedades

#### 8. `Invoke-WithSpinner`
```powershell
$result = Invoke-WithSpinner -ScriptBlock {
    # Proceso largo aquí
} -Message "Procesando..."
```
- Ejecuta scriptblock con spinner
- Espera a completación

#### 9. `Get-ValidatedInput`
```powershell
$path = Get-ValidatedInput -Prompt "Ruta: " `
  -ValidationScript { (Test-Path $_) } `
  -ErrorMessage "Ruta inválida"
```
- Entrada con validación personalizada
- Loop hasta entrada válida

#### 10. `Show-StatusBar`
```powershell
Show-StatusBar -Text "Operación en progreso" -Status "PROCESSING"
```
- Barra de estado destacada
- Estados: INFO, SUCCESS, WARNING, ERROR, PROCESSING

#### 11. `Show-SectionHeader`
```powershell
Show-SectionHeader -Title "Limpieza de Archivos" -Icon "▶"
```
- Encabezado de sección visual
- Iconos personalizables

#### 12. `Show-ImportantWarning`
```powershell
Show-ImportantWarning -Message "Esta acción no se puede deshacer!`nVerifica dos veces antes de continuar."
```
- Cuadro de advertencia con bordes rojo
- Múltiples líneas soportadas

#### 13. `Show-InfoBox`
```powershell
Show-InfoBox -Title "Información" -Content @(
    "Línea 1",
    "Línea 2",
    "Línea 3"
)
```
- Caja de información estructurada
- Múltiples líneas

### Uso como Módulo
```powershell
# Importar todas las funciones
. .\UI-Enhancements.ps1

# O desde dentro de otro script
Import-Module .\UI-Enhancements.ps1
```

---

## 🔗 Integración en Menú Principal

Las nuevas opciones disponibles en `Optimizador.ps1` son:

| Opción | Función | Script |
|--------|---------|--------|
| 37 | 🎨 Interfaz Gráfica | GUI-Optimizador.ps1 |
| 38 | 💾 Salud del SSD | SSD-Health.ps1 |
| 39 | 🎮 Optimizar GPU | GPU-Optimization.ps1 |
| 40 | 🌍 Idioma / Language | Localization.ps1 |
| 41 | 📈 Estadísticas Telemetría | Telemetry.ps1 |
| 42 | 📜 Historial de Operaciones | Operations-History.ps1 |

---

## 📋 Instalador Mejorado

El script `Instalar.ps1` ahora:

1. ✅ Verifica Windows 10/11
2. ✅ Verifica PowerShell 5.1+
3. ✅ Verifica política de ejecución
4. ✅ Verifica permisos de administrador
5. ✅ Verifica espacio en disco
6. ✅ **Crea estructura de directorios**:
   - `logs/` - Para archivos de log
   - `backups/` - Para copias de seguridad
   - `exports/` - Para reportes exportados
   - `%USERPROFILE%\OptimizadorPC/` - Directorio del usuario
   - `%USERPROFILE%\OptimizadorPC\history/` - Historial de operaciones
7. ✅ **Copia config.default.json → config.json**
8. ✅ **Verifica e instala Pester** si es necesario
9. ✅ Muestra resumen del sistema
10. ✅ Sugiere próximos pasos

---

## 🎯 Configuración Actualizada

El archivo `config.default.json` ahora incluye:

### GPU Optimization
```json
"gpu_optimization": {
  "enabled": true,
  "auto_detect": true,
  "nvidia_enabled": true,
  "amd_enabled": true,
  "intel_enabled": true,
  "disable_game_dvr": true,
  "disable_transparency": true,
  "enable_gpu_scheduling": true
}
```

### SSD Health Monitoring
```json
"ssd_health": {
  "enabled": true,
  "monitor_smart": true,
  "check_interval_hours": 24,
  "alert_on_high_temp": true,
  "alert_on_wear": true,
  "temp_threshold_celsius": 70,
  "wear_threshold_percent": 80,
  "auto_trim": true
}
```

### Telemetry Settings
```json
"telemetry_settings": {
  "enabled": false,
  "ask_on_startup": true,
  "local_storage_only": true,
  "max_events": 100,
  "auto_clear_days": 30
}
```

### Localization
```json
"localization": {
  "auto_detect_system_language": true,
  "fallback_language": "es",
  "supported_languages": ["es", "en", "pt", "fr"]
}
```

### Operation History
```json
"operation_history": {
  "enabled": true,
  "store_logs": true,
  "max_entries": 1000,
  "log_path": "%USERPROFILE%\\OptimizadorPC\\history",
  "auto_backup_history": true
}
```

---

## 🚀 Ejemplos de Uso

### Ejemplo 1: Registrar Operación
```powershell
# Al inicio de una operación
$start = Get-Date

# ... hacer trabajo ...

# Al finalizar
$duration = ([DateTime]::Now - $start).TotalSeconds
Add-OperationRecord -Operation "Limpieza Profunda" `
  -Status "SUCCESS" `
  -Description "Se eliminaron archivos temporales de sistema" `
  -Details "Archivos: 1523, Espacio: 2.3 GB" `
  -Duration $duration
```

### Ejemplo 2: Mostrar Menú con UI Mejorada
```powershell
. .\UI-Enhancements.ps1

$options = @{
    "1" = "Limpieza Rápida"
    "2" = "Limpieza Profunda"
    "3" = "Análisis"
    "0" = "Salir"
}

$choice = Show-EnhancedMenu -Options $options `
  -Title "OPTIMIZADOR DE COMPUTADORA v4.0" `
  -Description "Elige una acción"

if ($choice -ne "0") {
    Show-OperationResult -Operation "Acción seleccionada" `
      -Success $true `
      -Message "Opción: $($options[$choice])"
}
```

### Ejemplo 3: Generar Reporte
```powershell
Export-OperationHistoryHTML -Days 30 `
  -OutputPath "$env:USERPROFILE\Desktop\reporte-optimizacion.html"

# Abrir en navegador
Start-Process "$env:USERPROFILE\Desktop\reporte-optimizacion.html"
```

---

## 📊 Estadísticas del Proyecto Post-Polish v4.0.0

| Métrica | Cantidad |
|---------|----------|
| **Scripts PowerShell** | 51 (43 core + 8 framework) |
| **Módulos Framework** | 8 (+ 2 nuevos) |
| **Opciones de Menú** | 42 |
| **Funciones de UI** | 13 |
| **Idiomas Soportados** | 4 |
| **Líneas de Código** | ~3,500+ |
| **Test Coverage** | Extended.Tests.ps1 |
| **Documentación** | 11+ archivos |
| **GitHub Workflows** | 2 (CI/CD, Release) |

---

## ✅ Checklist de Completitud v4.0.0

- ✅ Versión consistente (v4.0.0 en todos lados)
- ✅ Menú principal con 42 opciones
- ✅ Todos los módulos integrados
- ✅ Instalador mejorado con setup completo
- ✅ Historial de operaciones implementado
- ✅ UI mejorada con componentes reutilizables
- ✅ Configuración centralizada expandida
- ✅ Git commits y push a repositorio
- ✅ Documentación actualizada
- ✅ CHANGELOG.md con todos los detalles

---

**Versión**: 4.0.0 Polish Edition
**Fecha**: Enero 2026
**Autor**: Fernando Farfán / GitHub Copilot
**Licencia**: MIT

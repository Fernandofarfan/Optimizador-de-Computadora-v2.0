# 📚 API DOCUMENTATION - PC Optimizer Suite v4.0.0

## Tabla de Contenidos
1. [Módulos Disponibles](#módulos-disponibles)
2. [Funciones de Notificaciones](#funciones-de-notificaciones)
3. [Funciones de Análisis Predictivo](#funciones-de-análisis-predictivo)
4. [Funciones de Performance](#funciones-de-performance)
5. [Ejemplos de Uso](#ejemplos-de-uso)
6. [Best Practices](#best-practices)

---

## Módulos Disponibles

### Core Modules
- **Logger-Advanced.ps1** - Sistema de logging avanzado
- **Config-Manager.ps1** - Gestión centralizada de configuración
- **Notifications-Manager.ps1** - Sistema de notificaciones inteligentes ⭐ NUEVO
- **Analysis-Predictor.ps1** - Análisis predictivo de rendimiento ⭐ NUEVO
- **Performance-Optimizer.ps1** - Optimización de performance ⭐ NUEVO

---

## Funciones de Notificaciones

### Send-CriticalNotification
**Descripción:** Envía una notificación crítica que requiere atención inmediata

**Sintaxis:**
```powershell
Send-CriticalNotification -Title <string> -Message <string> [-Category <string>]
```

**Parámetros:**
| Parámetro | Tipo | Obligatorio | Descripción |
|-----------|------|------------|-------------|
| Title | string | Sí | Título de la notificación |
| Message | string | Sí | Mensaje detallado |
| Category | string | No | Categoría (default: "System") |

**Ejemplo:**
```powershell
Send-CriticalNotification "🔴 RAM CRÍTICA" "Uso: 98%. Cierra programas."
```

**Output:**
- Toast notification en Windows
- Entrada en historial de notificaciones

---

### Send-WarningNotification
**Descripción:** Envía una notificación de advertencia

**Sintaxis:**
```powershell
Send-WarningNotification -Title <string> -Message <string> [-Category <string>]
```

**Ejemplo:**
```powershell
Send-WarningNotification "⚡ RAM Alta" "Uso: 85%. Considera cerrar programas."
```

---

### Send-InfoNotification
**Descripción:** Envía una notificación informativa

**Sintaxis:**
```powershell
Send-InfoNotification -Title <string> -Message <string> [-Category <string>]
```

**Ejemplo:**
```powershell
Send-InfoNotification "✓ Optimización completada" "Se liberaron 2.5 GB"
```

---

### Monitor-SystemResources
**Descripción:** Monitorea recursos en tiempo real y envía alertas automáticas

**Sintaxis:**
```powershell
Monitor-SystemResources [-Interval <int>] [-MaxChecks <int>]
```

**Parámetros:**
| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| Interval | int | 10 | Segundos entre checks |
| MaxChecks | int | 0 | Máximo checks (0 = infinito) |

**Ejemplo:**
```powershell
# Monitor continuo cada 5 segundos
Monitor-SystemResources -Interval 5

# Monitor 20 checks (100 segundos total)
Monitor-SystemResources -Interval 5 -MaxChecks 20
```

**Output:**
```
[14:32:10] RAM: 78% | Disco: 85% | CPU: 45%
[14:32:15] RAM: 79% | Disco: 85% | CPU: 52%
[14:32:20] RAM: 81% | Disco: 85% | CPU: 48%
```

---

### Get-NotificationLog
**Descripción:** Obtiene historial de notificaciones con filtros

**Sintaxis:**
```powershell
Get-NotificationLog [-Severity <string>] [-Category <string>] [-Last <int>]
```

**Parámetros:**
| Parámetro | Valores | Default | Descripción |
|-----------|---------|---------|-------------|
| Severity | Critical, Warning, Info | - | Filtrar por severidad |
| Category | string | - | Filtrar por categoría |
| Last | int | 50 | Últimas N notificaciones |

**Ejemplo:**
```powershell
# Últimas 20 notificaciones críticas
Get-NotificationLog -Severity Critical -Last 20

# Todas las notificaciones de recurso
Get-NotificationLog -Category Resource

# Últimas 100 notificaciones
Get-NotificationLog -Last 100
```

---

### Get-RAMUsage / Get-DiskUsage / Get-CPUUsage
**Descripción:** Obtiene porcentaje de uso de recursos

**Sintaxis:**
```powershell
Get-RAMUsage
Get-DiskUsage [-Drive <string>]
Get-CPUUsage
```

**Ejemplo:**
```powershell
$ram = Get-RAMUsage
Write-Host "RAM usage: $ram%"

$disk = Get-DiskUsage -Drive "D:"
Write-Host "Disk D: usage: $disk%"

$cpu = Get-CPUUsage
Write-Host "CPU usage: $cpu%"
```

---

## Funciones de Análisis Predictivo

### Collect-SystemMetrics
**Descripción:** Recopila métricas actuales del sistema y las guarda para análisis histórico

**Sintaxis:**
```powershell
Collect-SystemMetrics
```

**Output:**
```
RAMUsagePercent   : 78.45
DiskUsagePercent  : 85.32
CPUUsagePercent   : 45.67
ProcessCount      : 156
ServiceCount      : 92
TempSizeMB        : 1245.67
SystemHealth      : 63.51
```

**Ejemplo:**
```powershell
$metrics = Collect-SystemMetrics
$metrics | Format-Table -AutoSize
```

---

### Get-MaintenancePrediction
**Descripción:** Predice cuándo será necesario mantenimiento basándose en tendencias

**Sintaxis:**
```powershell
Get-MaintenancePrediction
```

**Output:**
```
RAMTrend            : 2.5
DiskTrend           : 4.2
CPUTrend            : 1.3
CurrentRAM          : 78.45
CurrentDisk         : 85.32
NeedsCleaning       : True
NeedsOptimization   : False
NeedsDefrag         : True
EstimatedCleaningDate : 17/01/2026
```

**Ejemplo:**
```powershell
$prediction = Get-MaintenancePrediction

if ($prediction.NeedsCleaning) {
    Write-Host "⚠️  Se recomienda limpieza profunda"
}

if ($prediction.EstimatedCleaningDate) {
    Write-Host "Próxima limpieza: $($prediction.EstimatedCleaningDate)"
}
```

---

### Get-AnalysisReport
**Descripción:** Genera reporte detallado de estadísticas en un período

**Sintaxis:**
```powershell
Get-AnalysisReport [-Days <int>]
```

**Parámetros:**
| Parámetro | Type | Default | Descripción |
|-----------|------|---------|-------------|
| Days | int | 30 | Días a analizar |

**Output:**
```
Period            : 30 días
DataPoints        : 30
AvgRAMUsage       : 72.34
PeakRAMUsage      : 92.45
AvgDiskUsage      : 80.12
PeakDiskUsage     : 92.87
TotalTempSpace    : 2.34 (GB)
AvgSystemHealth   : 65.43
```

**Ejemplo:**
```powershell
# Reporte de últimos 30 días
$report = Get-AnalysisReport -Days 30
$report | Format-Table -AutoSize

# Reporte de última semana
$weekReport = Get-AnalysisReport -Days 7
```

---

### Show-PredictionDashboard
**Descripción:** Muestra dashboard visual de predicciones en consola

**Sintaxis:**
```powershell
Show-PredictionDashboard
```

**Ejemplo:**
```powershell
Show-PredictionDashboard
```

---

## Funciones de Performance

### Invoke-ParallelTask
**Descripción:** Ejecuta tareas en paralelo de forma segura

**Sintaxis:**
```powershell
Invoke-ParallelTask -Items <array> -ScriptBlock <scriptblock> [-MaxJobs <int>] [-JobPrefix <string>]
```

**Parámetros:**
| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| Items | array | - | Items a procesar |
| ScriptBlock | scriptblock | - | Script a ejecutar por item |
| MaxJobs | int | 4 | Máximo jobs paralelos |
| JobPrefix | string | "OptJob" | Prefijo para nombres de jobs |

**Ejemplo:**
```powershell
$files = Get-ChildItem -Filter "*.log" -Recurse

$results = Invoke-ParallelTask -Items $files -ScriptBlock {
    param($file)
    @{
        File = $file.Name
        Size = $file.Length
    }
} -MaxJobs 4

$results | Format-Table -AutoSize
```

---

### Invoke-BatchProcessing
**Descripción:** Procesa items en batches eficientemente

**Sintaxis:**
```powershell
Invoke-BatchProcessing -Items <array> -ScriptBlock <scriptblock> [-BatchSize <int>]
```

**Ejemplo:**
```powershell
$items = 1..1000

$results = Invoke-BatchProcessing -Items $items -BatchSize 50 -ScriptBlock {
    param($batch)
    $batch | ForEach-Object { $_ * 2 }
}
```

---

### Get-WithCache
**Descripción:** Obtiene valor con caché automático

**Sintaxis:**
```powershell
Get-WithCache -Key <string> -ScriptBlock <scriptblock>
```

**Ejemplo:**
```powershell
# Primera llamada ejecuta el script
$data1 = Get-WithCache -Key "system-analysis" -ScriptBlock {
    Get-Process | Measure-Object
}

# Segunda llamada obtiene del caché
$data2 = Get-WithCache -Key "system-analysis" -ScriptBlock {
    Get-Process | Measure-Object
}
```

---

### Get-CacheStatistics
**Descripción:** Muestra estadísticas del caché

**Sintaxis:**
```powershell
Get-CacheStatistics
```

**Output:**
```
Total Items:    45
Cache Size:     12.34 MB
Valid Items:    42
Expired Items:  3
```

---

### Optimize-Memory
**Descripción:** Optimiza el uso de memoria del proceso actual

**Sintaxis:**
```powershell
Optimize-Memory
```

---

### Measure-Performance
**Descripción:** Realiza benchmark de una operación

**Sintaxis:**
```powershell
Measure-Performance -Operation <scriptblock> [-Iterations <int>] [-Description <string>]
```

**Ejemplo:**
```powershell
Measure-Performance -Operation { Get-Process } -Iterations 100 -Description "Get-Process Benchmark"
```

**Output:**
```
Average:     2.45 ms
Minimum:     1.23 ms
Maximum:     4.56 ms
```

---

## Ejemplos de Uso

### Ejemplo 1: Monitor de Recursos Completo
```powershell
# Importar módulos
. ".\Modules\Notifications-Manager.ps1"

# Monitorear por 5 minutos (60 checks de 5 segundos)
Monitor-SystemResources -Interval 5 -MaxChecks 60

# Ver historial de alertas
Get-NotificationLog -Severity Critical
```

### Ejemplo 2: Análisis Predictivo
```powershell
# Importar módulo
. ".\Modules\Analysis-Predictor.ps1"

# Recopilar métrica actual
$metric = Collect-SystemMetrics

# Ver predicción
$prediction = Get-MaintenancePrediction

# Mostrar dashboard
Show-PredictionDashboard

# Generar reporte
$report = Get-AnalysisReport -Days 30
$report | Format-Table
```

### Ejemplo 3: Optimización de Performance
```powershell
# Importar módulo
. ".\Modules\Performance-Optimizer.ps1"

# Procesar archivos en paralelo
$files = Get-ChildItem -Filter "*.txt" -Recurse
$results = Invoke-ParallelTask -Items $files -ScriptBlock {
    param($file)
    @{
        Name = $file.Name
        Lines = (Get-Content $file -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    }
}

# Mostrar estadísticas del caché
Get-CacheStatistics

# Optimizar memoria
Optimize-Memory

# Benchmark de operación
Measure-Performance -Operation { Get-Process } -Iterations 100
```

---

## Best Practices

### 1. Notificaciones
```powershell
# ✓ BIEN: Categoria específica
Send-CriticalNotification "RAM Critical" "Usage: 95%" -Category "Resource"

# ✗ MAL: Sin categoría
Send-CriticalNotification "Alert" "Something wrong"
```

### 2. Análisis Predictivo
```powershell
# ✓ BIEN: Recopilar datos regularmente
$task = Register-ScheduledJob -Name "CollectMetrics" -ScriptBlock {
    . "Modules\Analysis-Predictor.ps1"
    Collect-SystemMetrics
} -Trigger (New-JobTrigger -Daily -At 2AM)

# ✗ MAL: Solo analizar sin historial
$prediction = Get-MaintenancePrediction  # Requiere datos históricos
```

### 3. Performance
```powershell
# ✓ BIEN: Usar paralelización para listas grandes
$largeList = 1..10000
Invoke-ParallelTask -Items $largeList -MaxJobs 4

# ✗ MAL: Procesar secuencialmente
$largeList | ForEach-Object { SlowOperation $_ }

# ✓ BIEN: Usar caché para operaciones costosas
$data = Get-WithCache "expensive-operation" {
    ComplexAnalysis
}

# ✗ MAL: Ejecutar siempre
$data = ComplexAnalysis
```

### 4. Monitoreo
```powershell
# ✓ BIEN: Monitoreo configurado
Monitor-SystemResources -Interval 10 -MaxChecks 1440  # 4 horas

# ✗ MAL: Sin límite (consume recursos)
Monitor-SystemResources  # Infinito
```

---

## Troubleshooting

### Problema: "Módulo no encontrado"
```powershell
# Solución: Especificar ruta completa
. "C:\Path\To\Modules\Notifications-Manager.ps1"
```

### Problema: "Notificaciones no aparecen"
```powershell
# Solución: Verificar permisos y ejecutar como admin
# Requerimiento: Windows 10+, PowerShell con permisos de admin
```

### Problema: "Cache lleno"
```powershell
# Solución: Limpiar caché expirado
Clear-Cache
Get-CacheStatistics
```

---

**Documentación actualizada:** 12 Enero 2026  
**Versión:** v4.0.0  
**Autor:** PC Optimizer Suite Team

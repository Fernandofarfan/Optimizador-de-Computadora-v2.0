# Arquitectura del Proyecto

## 📐 Visión General

El **Optimizador de PC** es una suite de herramientas PowerShell modular diseñada para optimización y mantenimiento de sistemas Windows. El proyecto sigue una arquitectura de scripts independientes orquestados por un menú central.

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                     Usuario Final                            │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                  Optimizador.ps1 (Main Menu)                 │
│  - Interfaz de usuario                                       │
│  - Orquestación de módulos                                   │
│  - Gestión de logs                                           │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┬──────────────┐
        ↓               ↓               ↓              ↓
┌──────────────┐ ┌──────────────┐ ┌──────────┐ ┌──────────┐
│  Módulo de   │ │  Módulo de   │ │ Módulo de│ │ Módulo de│
│  Sistema     │ │  Red         │ │ Seguridad│ │ Análisis │
└──────┬───────┘ └──────┬───────┘ └────┬─────┘ └────┬─────┘
       │                │               │            │
       ↓                ↓               ↓            ↓
┌──────────────────────────────────────────────────────────┐
│              Windows APIs y Comandos                      │
│  WMI • .NET • PowerShell Cmdlets • Windows APIs          │
└──────────────────────────────────────────────────────────┘
```

## 📦 Módulos y Componentes

### 1. Core (Núcleo)

#### Optimizador.ps1
**Rol**: Script principal y punto de entrada
**Responsabilidades**:
- Presentar menú interactivo de 36 opciones
- Invocar scripts especializados
- Gestionar el flujo de la aplicación
- Coordinar logging global
- Verificar permisos de administrador

### 2. Módulos de Sistema

#### Limpieza-Automatica.ps1
- Limpieza de archivos temporales
- Vaciado de papelera de reciclaje
- Limpieza de caché del sistema
- Eliminación de archivos de actualización antiguos

#### Reparacion-Sistema.ps1
- SFC (System File Checker)
- DISM (Deployment Image Servicing)
- Verificación y reparación de integridad

#### Optimizacion-Arranque.ps1
- Gestión de programas de inicio
- Optimización de servicios
- Configuración de inicio rápido

### 3. Módulos de Red

#### Monitor-Red.ps1
- Monitoreo de tráfico en tiempo real
- Análisis de conexiones activas
- Bloqueo de procesos sospechosos
- Registro de actividad de red

#### Limpieza-Red.ps1
- Limpieza de caché DNS
- Reset de configuración de red
- Renovación de dirección IP

### 4. Módulos de Almacenamiento

#### Analisis-Disco.ps1
- Análisis de espacio en disco
- Detección de archivos grandes
- Generación de reportes de uso

#### Gestor-Duplicados.ps1
- Búsqueda de archivos duplicados
- Comparación por hash (MD5/SHA256)
- Eliminación interactiva de duplicados

#### Desfragmentar-Disco.ps1
- Desfragmentación de HDD
- Optimización de SSD (TRIM)
- Análisis de fragmentación

### 5. Módulos de Seguridad y Privacidad

#### Privacidad-Avanzada.ps1
**Características**:
- Control de permisos de aplicaciones (30+ configuraciones)
- Desactivación de telemetría de Windows
- Limpieza de historial de actividades
- Gestión de servicios de seguimiento

#### Analisis-Seguridad.ps1
- Verificación de actualizaciones
- Estado de Windows Defender
- Análisis de configuración de firewall

### 6. Módulos de Aplicaciones

#### Gestor-Aplicaciones.ps1
- Listado de aplicaciones instaladas
- Detección de bloatware (25+ patrones)
- Desinstalación de aplicaciones
- Gestión de aplicaciones de tienda

### 7. Módulos de Energía

#### Gestor-Energia.ps1
**Funcionalidades**:
- Gestión de planes de energía
- Creación de perfiles personalizados
- Monitoreo de consumo
- Análisis de salud de batería

### 8. Módulos de Respaldo

#### Backup-Sistema.ps1
- Creación de puntos de restauración
- Respaldo de drivers
- Respaldo de configuración del sistema

#### Backup-Nube.ps1
- Gestión de perfiles de respaldo
- Sincronización con OneDrive/Google Drive
- Compresión y encriptación (planificado)

#### Gestor-RestorePoints.ps1
- Creación de puntos de restauración
- Listado y gestión de puntos existentes
- Restauración del sistema

### 9. Módulos de Monitoreo

#### Monitor-Sistema.ps1
- Monitoreo de recursos en tiempo real
- Alertas de rendimiento
- Registro de métricas

#### Dashboard-Avanzado.ps1
**Características**:
- Visualización ASCII de métricas
- Gráficos de barras y sparklines
- Histórico de rendimiento
- Vista en tiempo real de CPU/RAM/Disco

#### Dashboard-Web.ps1
**Características** (v3.0):
- Servidor HTTP integrado
- API REST para monitoreo remoto
- Autenticación básica
- Endpoints JSON para métricas

### 10. Módulos de Inteligencia Artificial

#### Asistente-IA.ps1
**Características** (v3.0):
- Análisis inteligente de logs de eventos
- Base de conocimiento de 50+ patrones
- Diagnóstico automatizado
- Generación de reportes HTML
- Sugerencias contextuales

## 🔄 Flujo de Datos

### Flujo de Ejecución Típico

```
Usuario → Optimizador.ps1 → Selecciona Opción
                                    ↓
                            Verifica Permisos
                                    ↓
                            Invoca Módulo Específico
                                    ↓
                            Ejecuta Operaciones
                                    ↓
                    Captura Salida y Registra Logs
                                    ↓
                            Muestra Resultados
                                    ↓
                            Retorna al Menú
```

### Gestión de Logs

```
Cada Módulo
     ↓
Write-Log Function
     ↓
optimizador.log (archivo central)
     ↓
Rotación automática (opcional)
```

## 🗂️ Estructura de Archivos

```
Optimizador-de-Computadora/
│
├── Optimizador.ps1              # 🎯 Script principal (Menú de 36 opciones)
│
├── 📁 Módulos de Sistema
│   ├── Limpieza-Automatica.ps1
│   ├── Reparacion-Sistema.ps1
│   ├── Optimizacion-Arranque.ps1
│   ├── Optimizacion-Servicios.ps1
│   └── Limpieza-Registro.ps1
│
├── 📁 Módulos de Disco
│   ├── Analisis-Disco.ps1
│   ├── Desfragmentar-Disco.ps1
│   ├── Gestor-Duplicados.ps1      # v3.0
│   └── Liberador-Espacio.ps1
│
├── 📁 Módulos de Red
│   ├── Monitor-Red.ps1             # v3.0
│   ├── Limpieza-Red.ps1
│   └── Analisis-Red.ps1
│
├── 📁 Módulos de Aplicaciones
│   ├── Gestor-Aplicaciones.ps1     # v2.9
│   └── Actualizador-Apps.ps1
│
├── 📁 Módulos de Seguridad
│   ├── Privacidad-Avanzada.ps1     # v2.9
│   ├── Analisis-Seguridad.ps1
│   └── Gestor-Firewall.ps1
│
├── 📁 Módulos de Energía
│   └── Gestor-Energia.ps1          # v2.9
│
├── 📁 Módulos de Backup
│   ├── Backup-Sistema.ps1
│   ├── Backup-Nube.ps1
│   └── Gestor-RestorePoints.ps1
│
├── 📁 Módulos de Monitoreo
│   ├── Monitor-Sistema.ps1
│   ├── Dashboard-Avanzado.ps1
│   ├── Dashboard-Web.ps1           # v3.0
│   └── Asistente-IA.ps1            # v3.0
│
├── 📁 Módulos de Mantenimiento
│   └── Mantenimiento-Automatico.ps1
│
├── 📁 Documentación
│   ├── README.md
│   ├── CHANGELOG.md
│   ├── CONTRIBUTING.md
│   ├── CODE_OF_CONDUCT.md
│   └── ARCHITECTURE.md (este archivo)
│
├── 📁 Configuración
│   ├── .gitignore
│   ├── .gitattributes
│   ├── .editorconfig
│   └── PSScriptAnalyzerSettings.psd1
│
└── 📁 Datos (generados en tiempo de ejecución)
    ├── config.json              # Configuraciones de usuario
    ├── optimizador.log          # Logs de ejecución
    └── backups/                 # Respaldos generados
```

## 🔧 Tecnologías Utilizadas

### PowerShell Core
- **Versión**: 5.1+
- **Características usadas**:
  - Cmdlets nativos de Windows
  - WMI (Windows Management Instrumentation)
  - .NET Framework
  - COM Objects

### APIs y Servicios de Windows
- **Win32_***: Clases WMI para información del sistema
- **System.Net.HttpListener**: Servidor HTTP para Dashboard Web
- **System.IO.Compression**: Compresión de archivos
- **System.Security.Cryptography**: Hashing de archivos

### Comandos Nativos de Windows
- `powercfg`: Gestión de energía
- `netsh`: Configuración de red
- `sfc`: System File Checker
- `DISM`: Deployment Image Servicing
- `vssadmin`: Volume Shadow Copy Service

## 🎨 Patrones de Diseño

### 1. Patrón de Menú (Menu Pattern)
El script principal actúa como un despachador central que invoca módulos especializados.

### 2. Patrón de Fábrica (Factory Pattern)
Funciones de utilidad crean objetos de configuración según el contexto.

### 3. Patrón de Estrategia (Strategy Pattern)
Diferentes estrategias de limpieza/optimización según el tipo de sistema detectado.

### 4. Logging Centralizado
Todos los módulos usan una función `Write-Log` común para trazabilidad.

### 5. Separación de Responsabilidades
Cada script tiene una única responsabilidad bien definida.

## 🔐 Seguridad

### Principios de Seguridad Implementados

1. **Verificación de Permisos**
   - Todos los scripts críticos requieren elevación a administrador
   - Validación mediante `#Requires -RunAsAdministrator`

2. **Validación de Entrada**
   - Sanitización de rutas de archivo
   - Validación de opciones del usuario

3. **Manejo de Errores**
   - Try-Catch en operaciones críticas
   - Logging de excepciones
   - Recuperación graciosa de errores

4. **Mínimos Privilegios**
   - Solo se solicitan permisos cuando son necesarios
   - Operaciones de lectura no requieren elevación

## 📊 Rendimiento

### Optimizaciones Implementadas

1. **Ejecución Paralela** (planificado)
   - Uso de `Start-Job` para operaciones largas
   - Análisis paralelo de discos

2. **Caché de Datos**
   - Almacenamiento de métricas frecuentes
   - Reducción de llamadas a WMI

3. **Procesamiento por Lotes**
   - Agrupación de operaciones de archivo
   - Transacciones de registro

## 🚀 Roadmap Técnico

### Versión 4.0 (Planificada)

#### Arquitectura Modular Avanzada
- [ ] Convertir scripts en módulos PowerShell (.psm1)
- [ ] Implementar sistema de plugins
- [ ] API pública para extensiones

#### Cloud Integration
- [ ] Soporte para Azure Storage
- [ ] Sincronización con AWS S3
- [ ] Telemetría opcional

#### Machine Learning
- [ ] Predicción de necesidades de mantenimiento
- [ ] Detección de anomalías
- [ ] Optimización automática basada en patrones de uso

#### UI Mejorada
- [ ] Interfaz gráfica con WPF
- [ ] Dashboard web responsive
- [ ] Aplicación de escritorio moderna

## 📚 Referencias Técnicas

### Documentación de Microsoft
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [WMI Reference](https://docs.microsoft.com/windows/win32/wmisdk/)
- [.NET API Browser](https://docs.microsoft.com/dotnet/api/)

### Herramientas de Desarrollo
- **VSCode** con extensión PowerShell
- **PSScriptAnalyzer** para análisis de código
- **Pester** para testing (futuro)

## 🤝 Contribución

Para contribuir a la arquitectura del proyecto, consulta [CONTRIBUTING.md](CONTRIBUTING.md).

### Áreas de Contribución Técnica

- 🏗️ Refactorización de módulos
- 🧪 Implementación de tests
- 📊 Mejoras de rendimiento
- 🔒 Endurecimiento de seguridad
- 📱 Desarrollo de UI
- 🌐 Integración cloud

---

**Versión del Documento**: 3.0.0  
**Última Actualización**: 2024  
**Autor**: Fernando Farfan

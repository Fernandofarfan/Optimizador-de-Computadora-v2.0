# Changelog

Todos los cambios notables en este proyecto se documentan en este archivo.

## [2.7.0] - 2025-01-12

### ✨ Agregado - Herramientas Profesionales
- **📡 Monitor en Tiempo Real** - `Monitor-TiempoReal.ps1`
  - Dashboard continuo con actualización cada 2 segundos
  - Métricas en tiempo real: CPU, RAM, Disco con porcentajes
  - Velocidad de red: Descarga y subida en KB/s con deltas
  - Progress bars con codificación de colores (Verde <60%, Amarillo 60-80%, Rojo >80%)
  - Top 5 procesos por consumo de RAM con WorkingSet
  - Interfaz profesional con caracteres Unicode (cajas, barras)
  - Redibujado in-place con SetCursorPosition (sin scrolling)
  - Contador de iteraciones y timestamp
  - Salida con Ctrl+C

- **⚙️ Perfiles de Optimización** - `Perfiles-Optimizacion.ps1`
  - **🎮 Perfil Gaming**: Plan alto rendimiento, updates pausados 7 días, Game Bar off, prioridad alta, sin notificaciones, GPU rendimiento
  - **💼 Perfil Trabajo**: Plan equilibrado, notificaciones activas, updates normales, efectos visuales balanceados, prioridad normal
  - **🔋 Perfil Batería**: Ahorro de energía, CPU limitada 50-70%, brillo 70%, suspensiones 2-5 min, efectos mínimos, +30-50% duración
  - **⚡ Perfil Máximo Rendimiento**: Ultimate Performance plan, CPU 100%, sin suspensiones, PCI Express máximo, Core Parking off, servicios innecesarios desactivados
  - Aplicación instantánea con un clic
  - Recomendaciones post-aplicación

- **🎮 Optimizador de Juegos Específicos** - `Optimizar-Juegos.ps1`
  - Detección automática multi-plataforma: Steam (libraryfolders.vdf), Epic Games (manifests), Origin (LocalContent), GOG (Registry)
  - Optimización en tiempo real (mientras el juego corre)
  - Prioridad alta: PriorityClass = High
  - CPU Affinity dedicada: Todos los núcleos disponibles
  - GPU alto rendimiento por juego: DirectX UserGpuPreferences
  - Pantalla completa exclusiva: Mode=2 (mejor FPS)
  - Desactivación de overlays: Discord, GeForce Experience, Xbox Game Bar
  - Lista numerada de juegos detectados
  - Opción optimizar todos o individual
  - Mejora esperada: +10-30% FPS

- **🗂️ Limpieza Segura de Registro** - `Limpiar-Registro.ps1`
  - Backup automático en .reg antes de cualquier cambio
  - Limpieza de 5 áreas seguras: MUICache (caché iconos), SharedDLLs huérfanas, FileExts inválidas, Uninstall keys huérfanas, Documentos recientes
  - Exportación completa con reg export
  - Contadores: Analizadas, eliminadas, errores
  - Estimación de espacio liberado (~2KB por entrada)
  - Sin tocar áreas críticas: HKLM\SYSTEM, Run, Drivers
  - Instrucciones de restauración incluidas

- **💿 Desfragmentador Inteligente** - `Desfragmentar-Inteligente.ps1`
  - Detección automática tipo disco: Get-PhysicalDisk MediaType (HDD vs SSD)
  - Para HDD: Análisis de fragmentación con Optimize-Volume -Analyze, defrag solo si >10%, progress reporting, análisis before/after
  - Para SSD: TRIM con Optimize-Volume -ReTrim (sin defrag, previene desgaste), explicación automática
  - Soporte multi-unidad o selección individual
  - Cálculo de tiempo y mejora
  - Información educativa (HDD cada 1-3 meses, SSD automático Windows)

- **🔄 Gestor de Actualizaciones Avanzado** - `Gestor-Actualizaciones.ps1`
  - Pausar actualizaciones: 1-35 días con PauseUpdatesExpiryTime
  - Reanudar: Eliminar registry keys (Quality, Feature)
  - Ver estado actual: Pausado/Activo con días restantes
  - Historial: Win32_QuickFixEngineering últimas 20 actualizaciones
  - Buscar disponibles: Microsoft.Update.Session search IsInstalled=0
  - Instalación selectiva: Todas o elegir específicas por número
  - Información de severidad: Critical, Important, Moderate, Low
  - Tamaño de cada update en MB
  - Descarga e instalación con UpdateCollection
  - Detección de reinicio requerido

### 🔧 Mejorado
- **Menú Principal**: Añadidas opciones 19-24 (6 herramientas profesionales)
- **README.md**: Documentación completa v2.7 con 6 nuevas secciones detalladas
- **CHANGELOG.md**: Actualizado con todas las características técnicas de v2.7

### 📝 Documentación
- Guías detalladas de uso para cada perfil de optimización
- Explicaciones de detección de juegos multi-plataforma
- Instrucciones de restauración de registro
- Información sobre HDD vs SSD y cuándo desfragmentar
- Tutorial de control de Windows Update

## [2.6.0] - 2025-01-12

### ✨ Agregado
- **💾 Backup Completo de Drivers** - `Backup-Drivers.ps1`
  - Exportación automática de todos los drivers instalados
  - Export-WindowsDriver para cada dispositivo
  - Carpeta organizada: Backup-Drivers-[timestamp]
  - Filtrado de drivers Microsoft básicos (opcional)
  - Reporte INFO_BACKUP.txt con detalles completos
  - Información de proveedor, versión, fecha, clase
  - Identificación de drivers críticos para arranque
  - Instrucciones de restauración incluidas
  - Cálculo de tamaño total del backup

- **🦠 Limpieza de Malware y Adware** - `Limpiar-Malware.ps1`
  - Análisis de archivo HOSTS (redirecciones maliciosas)
  - Detección de tareas programadas sospechosas
  - Análisis de extensiones de navegador (Chrome)
  - Búsqueda de programas PUPs instalados
  - Detección de scripts ejecutables en TEMP
  - Identificación de procesos sospechosos
  - Escaneo rápido integrado con Windows Defender
  - Limpieza interactiva con confirmación de usuario
  - Backup automático antes de modificaciones

- **📄 Generador de Reportes PDF** - `Generar-Reporte-PDF.ps1`
  - Generación de reportes profesionales en HTML
  - Conversión automática a PDF (Chrome/Edge headless)
  - Diseño responsive con gradientes modernos
  - Métricas visuales: CPU, RAM, Disco con progress bars
  - Estado de seguridad con badges de color
  - Recomendaciones dinámicas personalizadas
  - Información detallada de hardware
  - Actualización de Windows Update verificada
  - Apertura automática en navegador
  - Compatible con impresión

- **📊 Historial de Optimizaciones** - `Historico-Optimizaciones.ps1`
  - Base de datos JSON persistente
  - Registro automático de fecha, script, descripción
  - Captura de métricas antes/después
  - Función Add-OptimizacionHistorial exportable
  - Visualización de últimas N optimizaciones
  - Estadísticas globales: Total, por script, resultados
  - Cálculo de espacio liberado acumulado
  - Exportación a TXT formateado
  - Limpieza automática de entradas antiguas (>90 días)
  - Registro manual de optimizaciones

### 🔧 Mejorado
- **Analizar-Seguridad.ps1**: Corregido error de compatibilidad internacional
  - Ahora usa SID S-1-5-32-544 en lugar de "Administradores"
  - Compatible con Windows en cualquier idioma
- Menú principal extendido a 18 opciones
- README actualizado con v2.6.0 completo
- CHANGELOG con detalles técnicos de todas las mejoras
- Consistencia en mensajes de error y warnings
- Integración Logger en todos los scripts nuevos

### 📝 Documentación
- Guías de uso para cada herramienta nueva
- Tabla de menú actualizada (opciones 15-18)
- Descripciones técnicas detalladas
- Ejemplos de uso para funciones avanzadas
- Requisitos de Chrome/Edge para PDFs

### 🐛 Corregido
- Error en Analizar-Seguridad.ps1 con grupo "Administradores" en sistemas en inglés
- Ahora usa SID universal para máxima compatibilidad

## [2.5.0] - 2025-01-12

### ✨ Agregado
- **💻 Análisis Hardware Detallado** - `Analizar-Hardware.ps1`
  - Análisis completo de CPU (modelo, núcleos, velocidad, carga)
  - Información detallada de RAM (módulos, velocidad, capacidad)
  - Estado de discos con verificación SMART de salud
  - Datos de GPU (modelo, VRAM, resolución, driver)
  - Información de placa base y BIOS
  - Benchmark rápido (CPU, RAM, Disco) con score general
  - Recomendaciones personalizadas según hardware
  - Reportes con timestamps en formato texto

- **⏰ Tareas Programadas Automáticas** - `Crear-TareasProgramadas.ps1`
  - Limpieza semanal programada (Domingos 2:00 AM)
  - Análisis de seguridad mensual (día 1 del mes, 3:00 AM)
  - Backup automático de logs (días 1 y 15, 4:00 AM)
  - Análisis de sistema semanal (Lunes 1:00 AM)
  - Ejecuta con privilegios SYSTEM para máximo acceso
  - Gestión desde Programador de Tareas de Windows
  - Script inline para compresión de logs

- **🌐 Optimización de Red Avanzada** - `Optimizar-Red-Avanzada.ps1`
  - Test de conectividad a 5 servidores (latencia promedio)
  - Benchmark DNS de 4 proveedores (Google, CloudFlare, OpenDNS, Quad9)
  - Optimización automática de MTU (prueba 6 tamaños)
  - Limpieza completa: DNS flush, Winsock reset, TCP/IP reset
  - Configuración avanzada: TCP autotune, DNS CloudFlare 1.1.1.1
  - Detección automática del DNS más rápido
  - Reportes con métricas de red y recomendaciones

- **📊 Comparador de Rendimiento** - `Comparar-Rendimiento.ps1`
  - Sistema de snapshots antes/después de optimizaciones
  - Captura de métricas: CPU%, RAM%, Disco libre, Servicios, Startup
  - Comparación con cálculo de deltas y porcentajes
  - Persistencia en JSON para historial
  - Visualización con colores (verde=mejora, rojo=empeora)
  - Evaluación automática (X/4 mejoras detectadas)
  - Función reutilizable Get-SystemSnapshot

- **🔔 Sistema de Notificaciones** - `Notificaciones.ps1`
  - Notificaciones Toast nativas de Windows 10/11
  - Función Send-ToastNotification con 4 tipos
  - Iconos visuales: ✅ SUCCESS, ⚠️ WARNING, ❌ ERROR, ℹ️ INFO
  - API Windows.UI.Notifications integrada
  - Módulo exportable para uso en otros scripts
  - Notificaciones persistentes en Action Center

- **🔍 Diagnóstico Automático** - `Diagnostico-Automatico.ps1`
  - Detección inteligente de 8 categorías de problemas
  - Alertas críticas: Disco <10%, RAM >90%, servicios caídos
  - Advertencias: Espacio bajo, RAM/CPU alta, muchos startups
  - Verificación de Windows Defender activo
  - Conteo de actualizaciones pendientes
  - Detección de procesos con alto consumo (>500MB)
  - Recomendaciones automáticas para cada problema
  - Resumen ejecutivo con colores (verde/amarillo/rojo)

### 🔧 Mejorado
- Menú principal actualizado con 6 nuevas opciones (10-14)
- README extendido con documentación de v2.5.0
- CHANGELOG actualizado con detalles técnicos
- Integración Logger en todos los nuevos scripts
- Consistencia en formato de reportes y outputs
- Verificaciones de permisos admin donde requerido

### 📝 Documentación
- Guías de uso para cada nueva herramienta
- Tabla de menú completa con tiempos y permisos
- Descripciones técnicas de funcionalidades
- Requisitos de sistema actualizados

## [2.4.0] - 2025-01-12

### ✨ Agregado
- **🎮 Modo Gaming / Alto Rendimiento** - `Optimizar-ModoGaming.ps1`
  - Plan de energía configurado automáticamente a Alto Rendimiento
  - Pausa temporal de Windows Update (7 días)
  - Deshabilitación de Xbox Game Bar y DVR
  - Desactivación temporal de notificaciones
  - Optimización de efectos visuales para máximo rendimiento
  - Limpieza de RAM Standby (memoria en espera)
  - Ajuste de prioridades de procesos en primer plano
  - Mejora estimada de FPS: 10-20% en gaming
  - Integración completa con Logger

- **⚙️ Sistema de Configuración JSON** - `config.json`
  - Archivo de configuración centralizado
  - Personalización de limpieza profunda (días de logs, componentes incluidos)
  - Servicios excluidos de optimización (lista personalizable)
  - Configuración de backup y logging
  - Parámetros de modo gaming ajustables
  - Verificaciones de seguridad selectivas
  - Opciones avanzadas para usuarios expertos
  - Documentado con comentarios descriptivos

- **📊 Dashboard HTML Interactivo** - `docs/dashboard.html`
  - Panel de control visual del sistema
  - Monitoreo en tiempo real: CPU, RAM, Disco
  - Estado de seguridad: Defender, Firewall, Updates
  - Botones de acción rápida para cada script
  - Registro de actividad con logs en tiempo real
  - Barras de progreso animadas
  - Diseño responsive (móvil, tablet, desktop)
  - Gradientes modernos y efectos visuales
  - Estadísticas de optimizaciones realizadas

### 🔧 Mejorado
- Menú principal actualizado con opción [9] Modo Gaming
- README con sección completa de nuevas funcionalidades v2.4
- Versión actualizada en todos los archivos principales
- Documentación de uso de config.json y dashboard

### 📝 Documentación
- Guía de uso del sistema de configuración JSON
- Instrucciones para abrir y usar el dashboard HTML
- Recomendaciones de uso del modo gaming
- Explicación de parámetros configurables

## [2.3.0] - 2025-01-12

### ✨ Agregado
- **🔄 Script de Reversión** - `Revertir-Cambios.ps1`
  - Detecta y reactiva servicios deshabilitados por el optimizador
  - Permite reactivar servicios selectivamente o en bloque
  - Opción de iniciar servicios reactivados inmediatamente
  - Lista puntos de restauración creados por el optimizador
  - Limpieza de logs antiguos y reportes generados
  - Muestra estadísticas de espacio ocupado por logs
  - Información del estado actual del sistema (RAM, disco, programas en inicio)
  - Recomendaciones sobre cuándo usar reversión vs puntos de restauración

- **🔒 Módulo de Seguridad** - `Analizar-Seguridad.ps1`
  - Análisis completo de Windows Defender (protección en tiempo real, cloud, definiciones)
  - Verificación de Firewall de Windows (todos los perfiles)
  - Detección de actualizaciones pendientes de Windows Update
  - Comprobación de UAC (Control de Cuentas de Usuario)
  - Estado de BitLocker (cifrado de disco)
  - Análisis de cuentas de usuario y permisos de administrador
  - Verificación de cuenta de invitado
  - Estado de servicios críticos de seguridad (WinDefend, Firewall, Update, etc.)
  - Generación de reporte detallado en `Reporte-Seguridad-[fecha].txt`
  - Sistema de puntuación: ✅ Correcto, ⚠️ Warning, ❌ Crítico
  - Resumen ejecutivo con estadísticas

- **📸 Documentación Visual** - `docs/SCREENSHOTS.md`
  - Guía completa para capturar screenshots del proyecto
  - Instrucciones para 6 capturas principales (menú, análisis, optimización, reportes, etc.)
  - Especificaciones técnicas (resolución, formato, compresión)
  - Herramientas recomendadas (Recorte Windows, ShareX)
  - Mejores prácticas y checklist de calidad
  - Plantillas para integración en README.md
  - Estructura de directorios `docs/screenshots/`

### 🔧 Mejorado
- README actualizado con información de nuevas funcionalidades
- Menú principal expandido con opciones [7] Analizar Seguridad y [8] Revertir Cambios
- Mejor organización de estructura de archivos
- Documentación de comandos de mantenimiento

### 📝 Documentación
- Sección "Nuevas Funciones en v2.3" agregada al README
- Guía de uso para Revertir-Cambios.ps1 y Analizar-Seguridad.ps1
- Documentación visual con instrucciones de captura
- Actualización de estructura de archivos con nuevos módulos

## [2.2.0] - 2026-01-12

### ✨ Agregado
- **Templates de GitHub para Issues y PRs**
  - `.github/ISSUE_TEMPLATE/bug_report.md` - Template estructurado para reportar bugs
  - `.github/ISSUE_TEMPLATE/feature_request.md` - Template para solicitudes de funcionalidad
  - `.github/PULL_REQUEST_TEMPLATE.md` - Template completo para pull requests
  - `.github/CODE_OF_CONDUCT.md` - Código de conducta basado en Contributor Covenant
- **Sistema de Puntos de Restauración**
  - `Crear-PuntoRestauracion.ps1` - Crea restore points antes de cambios críticos
  - Verificación de System Restore habilitado
  - Validación de espacio en disco
  - Integración automática en módulos de limpieza y servicios
- **Integración completa del Logger**
  - Analizar-Sistema.ps1 ahora registra todo el proceso de análisis
  - Limpieza-Profunda.ps1 registra archivos eliminados y espacio liberado
  - Optimizar-Servicios.ps1 registra cambios en servicios con estado previo

### 🔧 Mejorado
- Los módulos críticos (Limpieza y Servicios) ahora sugieren crear punto de restauración
- Logging detallado en todas las operaciones principales
- Mejor trazabilidad de errores con niveles de severidad
- README actualizado con sección de backup y logging integrado

### 🛡️ Seguridad
- Puntos de restauración garantizan reversibilidad de cambios
- Validación de permisos de administrador antes de operaciones críticas
- Logs completos de todas las modificaciones al sistema
## [2.2.0] - 2026-01-12

### ✨ Agregado
- **Templates de GitHub** - Sistema completo de templates para contribución
  - Bug report template con secciones estructuradas
  - Feature request template con casos de uso
  - Pull request template con checklist completo
  - Código de conducta (Contributor Covenant 1.4)
- **Integración de Logger en Módulos** - Logging completo en scripts principales
  - Analizar-Sistema.ps1 ahora registra todo el análisis
  - Limpieza-Profunda.ps1 registra archivos eliminados y espacio liberado
  - Optimizar-Servicios.ps1 registra servicios modificados y estados
  - Logs con timestamps y niveles de severidad
- **Sistema de Backup/Restore** - Crear-PuntoRestauracion.ps1
  - Creación de puntos de restauración de Windows
  - Verificación automática de System Restore
  - Habilitación de System Restore si está deshabilitado
  - Integración en módulos críticos (Limpieza-Profunda, Optimizar-Servicios)
  - Sugerencia automática antes de operaciones de riesgo
  - Listado de puntos de restauración recientes
  - Instrucciones para restaurar el sistema

### 🔧 Mejorado
- Todos los módulos ahora tienen trazabilidad completa
- Mejor manejo de errores con logs detallados
- Transparencia en operaciones de limpieza (MB liberados)
- Sistema de backup proactivo antes de cambios críticos

## [2.1.0] - 2026-01-12

### ✨ Agregado
- **Sistema de Logging Avanzado** - Logger.ps1 con rotación automática de logs
  - Rotación automática al alcanzar 5 MB por archivo
  - Niveles de severidad: DEBUG, INFO, SUCCESS, WARNING, ERROR, CRITICAL
  - Exportación de reportes de errores y advertencias
  - Historial completo de operaciones
  - Configuración flexible por módulo
- **GitHub Actions CI/CD** - Validación automática de sintaxis PowerShell
  - Workflow para validar todos los scripts en push/PR
  - Verificación de estructura del proyecto
  - Análisis de formato de código (BOM, tabs, líneas largas)
- **Guía de Contribución** - CONTRIBUTING.md con proceso completo
  - Instrucciones para fork y clone
  - Estándares de código PowerShell
  - Nomenclatura de ramas y commits (Conventional Commits)
  - Proceso de revisión de PRs
- **Política de Seguridad** - SECURITY.md con alcance y divulgación
  - Versiones soportadas
  - Proceso para reportar vulnerabilidades
  - Alcance de operaciones sensibles
  - Auditoría de código
- **Script de Instalación** - Instalar.ps1 para configuración inicial
  - Verificación de requisitos del sistema
  - Validación de archivos del proyecto
  - Configuración automática de permisos
  - Creación de directorios necesarios
- **Ejemplo de Logging** - Ejemplo-Logger.ps1 con casos de uso
  - 8 ejemplos prácticos de uso del logger
  - Integración en funciones personalizadas
  - Guía de mejores prácticas
- **Script de Actualización** - Actualizar.ps1 para verificar nuevas versiones
  - Consulta API de GitHub para obtener última release
  - Compara versión instalada con disponible
  - Muestra changelog de nuevas versiones
  - Abre navegador automáticamente para descargar

### 🔧 Mejorado
- README actualizado con sección de logging
- .gitignore expandido para logs/ y archivos de backup
- Estructura profesional del proyecto con documentación completa
- Badges actualizados en README

## [2.0.0] - 2026-01-12

### ✨ Agregado
- **Menú Principal Profesional** - Interfaz centralizada con 6 opciones
- **Análisis Completo del Sistema** - Reporte detallado de RAM, CPU, Disco
- **Limpieza Inteligente** - Modo rápido y profundo (admin)
- **Optimización de Servicios** - Desactiva telemetría y servicios innecesarios
- **Gestión de Inicio** - Visualiza y desactiva programas de startup
- **Herramientas Avanzadas** - SFC, DISM, DNS Flush, Winsock Reset, Defrag
- **GitHub Pages** - Landing page profesional con documentación
- **Lanzador Admin** - EJECUTAR-COMO-ADMIN.bat para permisos elevados
- **Documentación Completa** - README.md, Guía de uso, Troubleshooting

### 🔧 Mejorado
- Estructura de código modular y reutilizable
- Detección automática de permisos de administrador
- Manejo robusto de errores en todos los módulos
- Set-Location automático para evitar errores de ruta
- Interfaz limpia y profesional en todos los scripts

### 🐛 Corregido
- Error de "archivo no encontrado" cuando se ejecuta como admin
- Problemas de rutas con espacios en el nombre de carpeta
- Manejo de caracteres especiales en output
- Incompatibilidades con terminales antiguas

### 🔒 Seguridad
- Validación de permisos antes de operaciones sensibles
- Modo seguro para PCs prestadas (sin borrado de archivos)
- Reversibilidad de todos los cambios
- Sin conexión a internet (excepto DISM)
- Sin colección de datos personales

### 📦 Archivos del Proyecto (v2.2.0)
- `Optimizador.ps1` - Menú maestro
- `Analizar-Sistema.ps1` - Análisis de sistema (con logging integrado)
- `Optimizar-Sistema-Seguro.ps1` - Optimización segura
- `Limpieza-Profunda.ps1` - Limpieza avanzada (con logging y backup)
- `Optimizar-Servicios.ps1` - Gestión de servicios (con logging y backup)
- `Gestionar-Procesos.ps1` - Startup y RAM
- `Reparar-Red-Sistema.ps1` - Reparación avanzada
- `Logger.ps1` - Sistema de logging avanzado
- `Crear-PuntoRestauracion.ps1` - Creador de puntos de restauración
- `Instalar.ps1` - Script de instalación y verificación
- `Actualizar.ps1` - Verificador de actualizaciones
- `Ejemplo-Logger.ps1` - Ejemplos de uso del logger
- `EJECUTAR-COMO-ADMIN.bat` - Lanzador con permisos
- `README.md` - Documentación principal
- `CONTRIBUTING.md` - Guía para contribuidores
- `SECURITY.md` - Política de seguridad
- `CHANGELOG.md` - Este archivo
- `.gitignore` - Configuración Git
- `LICENSE` - MIT License
- `.github/workflows/powershell-ci.yml` - GitHub Actions CI
- `.github/ISSUE_TEMPLATE/bug_report.md` - Template de bug report
- `.github/ISSUE_TEMPLATE/feature_request.md` - Template de feature request
- `.github/PULL_REQUEST_TEMPLATE.md` - Template de pull request
- `.github/CODE_OF_CONDUCT.md` - Código de conducta
- `docs/index.html` - Landing page
- `docs/style.css` - Estilos profesionales
- `docs/README.md` - Documentación del sitio web

---

## Notas Futuras

### Planned [2.3.0]
- [ ] Screenshots en README y documentación
- [ ] Módulo de seguridad (Windows Defender, Firewall, UAC)
- [ ] Script de desinstalación/reversión completa
- [ ] Dashboard HTML con gráficos (Chart.js)
- [ ] Modo Gaming para optimización temporal
- [ ] Scheduler de limpiezas automáticas
- [ ] Integración del Logger en todos los módulos
- [ ] Interfaz gráfica (GUI) en PowerShell
- [ ] Soporte para Windows 7/8
- [ ] Estadísticas de uso (local, sin cloud)

### Contribuciones Bienvenidas
Se aceptan pull requests, issues y sugerencias.

---

**Versión Actual**: 2.0.0  
**Estado**: Estable y Production-Ready  
**Licencia**: MIT  
**Autor**: Fernando Farfan

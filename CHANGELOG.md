# Changelog

Todos los cambios notables en este proyecto se documentan en este archivo.

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

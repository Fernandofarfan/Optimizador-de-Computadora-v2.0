# Changelog

Todos los cambios notables en este proyecto se documentan en este archivo.

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

### 📦 Archivos del Proyecto
- `Optimizador.ps1` - Menú maestro
- `Analizar-Sistema.ps1` - Análisis de sistema
- `Optimizar-Sistema-Seguro.ps1` - Optimización segura
- `Limpieza-Profunda.ps1` - Limpieza avanzada
- `Optimizar-Servicios.ps1` - Gestión de servicios
- `Gestionar-Procesos.ps1` - Startup y RAM
- `Reparar-Red-Sistema.ps1` - Reparación avanzada
- `Logger.ps1` - Sistema de logging avanzado
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
- `.github/workflows/powershell-ci.yml` - GitHub Actions
- `docs/index.html` - Landing page
- `docs/style.css` - Estilos profesionales
- `docs/README.md` - Documentación del sitio web

---

## Notas Futuras

### Planned [2.2.0]
- [ ] Integración del Logger en todos los módulos
- [ ] Interfaz gráfica (GUI) en PowerShell
- [ ] Soporte para Windows 7/8
- [ ] Backups automáticos antes de cambios
- [ ] Restore points automáticos
- [ ] Estadísticas de uso (local, sin cloud)
- [ ] Programador de limpiezas automáticas
- [ ] Módulo de actualización de drivers
- [ ] Modo gaming (optimización para juegos)

### Contribuciones Bienvenidas
Se aceptan pull requests, issues y sugerencias.

---

**Versión Actual**: 2.0.0  
**Estado**: Estable y Production-Ready  
**Licencia**: MIT  
**Autor**: Fernando Farfan

# Changelog

Todos los cambios notables en este proyecto se documentan en este archivo.

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
- `EJECUTAR-COMO-ADMIN.bat` - Lanzador con permisos
- `README.md` - Documentación principal
- `.gitignore` - Configuración Git
- `LICENSE` - MIT License
- `docs/index.html` - Landing page
- `docs/style.css` - Estilos profesionales

---

## Notas Futuras

### Planned [2.1.0]
- [ ] Interfaz gráfica (GUI) en PowerShell
- [ ] Soporte para Windows 7/8
- [ ] Backups automáticos antes de cambios
- [ ] Restore points automáticos
- [ ] Estadísticas de uso (local, sin cloud)
- [ ] Programador de limpiezas automáticas

### Contribuciones Bienvenidas
Se aceptan pull requests, issues y sugerencias.

---

**Versión Actual**: 2.0.0  
**Estado**: Estable y Production-Ready  
**Licencia**: MIT  
**Autor**: Fernando Farfan

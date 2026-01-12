# 📸 Guía de Screenshots

Esta guía te ayudará a capturar capturas de pantalla del **PC Optimizer Suite** para la documentación.

## 🎯 Objetivo

Crear documentación visual que ayude a los usuarios a entender:
- La interfaz del menú principal
- Los resultados del análisis del sistema
- El proceso de optimización
- Los reportes generados

---

## 📋 Capturas Necesarias

### 1. **Menu Principal** (`menu-principal.png`)
- **Qué capturar:** La ventana de PowerShell mostrando el menú principal del `Optimizador.ps1`
- **Cómo:** 
  1. Ejecuta `Optimizador.ps1` como administrador
  2. Espera a que aparezca el menú completo con las 6 opciones
  3. Presiona `Windows + Shift + S` para captura parcial
  4. Selecciona toda la ventana de PowerShell
  5. Guarda como `menu-principal.png` en `docs/screenshots/`

**Debe mostrar:**
- Banner del PC Optimizer Suite con versión
- Las 6 opciones del menú numeradas
- La opción de salida (0)
- El prompt esperando entrada

---

### 2. **Análisis del Sistema** (`analisis-sistema.png`)
- **Qué capturar:** Resultados completos del análisis del sistema
- **Cómo:**
  1. Ejecuta la opción `[1] Analizar Sistema`
  2. Espera a que complete el análisis
  3. Captura la ventana mostrando los resultados
  4. Guarda como `analisis-sistema.png`

**Debe mostrar:**
- CPU, RAM, Disco detectados
- Servicios activos/deshabilitados
- Programas en inicio
- Estado general del sistema
- Mensaje "Análisis completado"

---

### 3. **Optimización en Progreso** (`optimizacion-progreso.png`)
- **Qué capturar:** El proceso de optimización ejecutándose
- **Cómo:**
  1. Ejecuta la opción `[2] Optimización Completa`
  2. Cuando veas el mensaje de servicios siendo deshabilitados
  3. Captura rápidamente (tiene que mostrar actividad)
  4. Guarda como `optimizacion-progreso.png`

**Debe mostrar:**
- Mensajes de "Optimizando servicios..."
- Servicios siendo deshabilitados uno por uno
- Porcentaje de progreso o checkmarks (✅)
- Limpieza en curso

---

### 4. **Reporte Generado** (`reporte-ejemplo.png`)
- **Qué capturar:** Un reporte de texto abierto en el Bloc de notas
- **Cómo:**
  1. Ejecuta cualquier opción que genere reporte (`Analizar-Sistema.ps1`)
  2. Abre el archivo `Reporte-Sistema-*.txt` generado
  3. Captura la ventana del Bloc de notas
  4. Guarda como `reporte-ejemplo.png`

**Debe mostrar:**
- Header del reporte con fecha/hora
- Información del sistema
- Resultados formateados
- Formato claro y legible

---

### 5. **Análisis de Seguridad** (`seguridad-analisis.png`)
- **Qué capturar:** Resultados del nuevo módulo de seguridad
- **Cómo:**
  1. Ejecuta `Analizar-Seguridad.ps1`
  2. Espera a que complete todas las verificaciones
  3. Captura el resumen final con estadísticas
  4. Guarda como `seguridad-analisis.png`

**Debe mostrar:**
- Análisis de Windows Defender
- Estado del Firewall
- Actualizaciones pendientes
- Resumen con checkmarks y warnings
- Estadísticas finales (✅ OK, ⚠️ Warnings, ❌ Critical)

---

### 6. **Script de Reversión** (`revertir-cambios.png`)
- **Qué capturar:** Interfaz del script de reversión
- **Cómo:**
  1. Ejecuta `Revertir-Cambios.ps1`
  2. Espera a que muestre los servicios deshabilitados
  3. Captura antes de responder al prompt
  4. Guarda como `revertir-cambios.png`

**Debe mostrar:**
- Lista de servicios deshabilitados detectados
- Opciones para reactivar servicios
- Información de puntos de restauración
- Estadísticas de logs/reportes

---

## 🛠️ Herramientas Recomendadas

### Opción 1: Recorte de Windows (Recomendado)
- **Atajo:** `Windows + Shift + S`
- **Ventajas:** Rápido, integrado, guarda en portapapeles
- **Uso:** Captura > Pega en Paint > Guarda como PNG

### Opción 2: Snipping Tool
- **Ubicación:** Busca "Recortes" en el menú inicio
- **Ventajas:** Editor básico incluido, retraso de captura

### Opción 3: ShareX (Avanzado)
- **Descarga:** https://getsharex.com/
- **Ventajas:** Anotaciones, flechas, bordes automáticos
- **Ideal para:** Documentación profesional

---

## 📐 Especificaciones Técnicas

### Configuración de PowerShell
Antes de capturar, configura PowerShell para máxima legibilidad:

```powershell
# Tamaño de ventana óptimo
$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120,40)

# Buffer para scroll
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120,3000)

# Colores recomendados (por defecto están bien)
# Fondo: Azul oscuro / Texto: Blanco
```

### Resolución y Formato
- **Formato:** PNG (mejor calidad, sin pérdida)
- **Ancho mínimo:** 800px
- **Ancho máximo:** 1920px
- **Relación de aspecto:** Mantener original

### Calidad
- **Comprimir:** Sí, pero mantener legibilidad del texto
- **Herramienta:** TinyPNG o ImageOptim
- **Tamaño objetivo:** < 500KB por imagen

---

## 📁 Estructura de Archivos

Organiza las capturas así:

```
docs/
├── screenshots/
│   ├── menu-principal.png
│   ├── analisis-sistema.png
│   ├── optimizacion-progreso.png
│   ├── reporte-ejemplo.png
│   ├── seguridad-analisis.png
│   └── revertir-cambios.png
└── SCREENSHOTS.md (este archivo)
```

---

## 🎨 Mejores Prácticas

### ✅ SÍ HACER:
- Capturar con ventana PowerShell en foco
- Esperar a que termine de renderizar
- Incluir título de la ventana
- Usar fondo oscuro de PowerShell (por defecto)
- Mostrar texto completo sin cortar

### ❌ NO HACER:
- Capturar con errores o texto truncado
- Incluir información personal (nombres de usuario)
- Usar resoluciones muy bajas
- Capturar con otras ventanas superpuestas
- Guardar en formatos JPG (pérdida de calidad)

---

## 🔗 Integración con README

Una vez tengas las capturas, actualiza el `README.md` así:

```markdown
## 📸 Capturas de Pantalla

### Menú Principal
![Menú Principal](docs/screenshots/menu-principal.png)

### Análisis del Sistema
![Análisis del Sistema](docs/screenshots/analisis-sistema.png)

### Optimización en Progreso
![Optimización](docs/screenshots/optimizacion-progreso.png)

### Reporte Generado
![Reporte](docs/screenshots/reporte-ejemplo.png)

### Análisis de Seguridad
![Seguridad](docs/screenshots/seguridad-analisis.png)

### Reversión de Cambios
![Revertir](docs/screenshots/revertir-cambios.png)
```

---

## ✅ Checklist de Calidad

Antes de publicar, verifica:

- [ ] Todas las 6 capturas están presentes
- [ ] Los archivos PNG están optimizados (< 500KB cada uno)
- [ ] El texto es legible al 100% de zoom
- [ ] No hay información personal visible
- [ ] Los colores se ven correctamente
- [ ] Las capturas muestran el flujo completo del programa
- [ ] El README.md incluye las referencias a las imágenes

---

## 📞 Soporte

Si tienes dudas sobre qué capturar o cómo editar las imágenes:
1. Revisa los ejemplos en proyectos similares de GitHub
2. Consulta la documentación de ShareX para anotaciones
3. Usa Paint para recortes básicos si es necesario

---

**Última actualización:** 2024-01-XX  
**Autor:** PC Optimizer Suite Team  
**Versión:** 1.0

# Política de Seguridad

## Versiones Soportadas

| Versión | Soporte          |
| ------- | ---------------- |
| 2.0.x   | ✅ Soportada     |
| < 2.0   | ❌ No soportada  |

## Reportar una Vulnerabilidad

La seguridad de este proyecto es una prioridad. Si descubres una vulnerabilidad de seguridad, por favor repórtala de manera responsable.

### Cómo Reportar

**NO** abras un issue público para vulnerabilidades de seguridad.

En su lugar:

1. **Envía un email** a: [Tu email o crear uno específico]
   - Asunto: `[SEGURIDAD] Vulnerabilidad en Optimizador de Computadora`
   
2. **Incluye la siguiente información**:
   - Descripción detallada de la vulnerabilidad
   - Pasos para reproducir el problema
   - Versión afectada
   - Impacto potencial
   - Sugerencias de mitigación (si las tienes)

3. **Tiempo de respuesta esperado**:
   - Confirmación de recepción: **24 horas**
   - Evaluación inicial: **72 horas**
   - Actualización de estado: **7 días**

### Proceso de Divulgación

1. **Investigación**: Verificamos y reproducimos la vulnerabilidad
2. **Desarrollo de parche**: Creamos una solución
3. **Notificación privada**: Te informamos antes del release público
4. **Release**: Publicamos el parche en una nueva versión
5. **Divulgación pública**: Anunciamos el fix después de que los usuarios tengan tiempo de actualizar (generalmente 7 días)

### Alcance de Seguridad

Este proyecto maneja operaciones sensibles del sistema. Áreas de atención:

#### Operaciones Privilegiadas
- **Administrador requerido**: Módulos de limpieza profunda y optimización de servicios
- **Validación de permisos**: Verificación antes de operaciones administrativas
- **Reversibilidad**: Los cambios en servicios pueden revertirse manualmente

#### Riesgos Potenciales
- **Modificación de servicios de Windows**: Puede afectar funcionalidad del sistema
- **Eliminación de archivos temporales**: Limpieza permanente sin papelera de reciclaje en algunos casos
- **Cambios en registro**: Modificación de claves de inicio automático

#### No Realizado por el Proyecto
- ❌ **NO** recopila información personal
- ❌ **NO** se conecta a servidores externos
- ❌ **NO** modifica archivos del usuario
- ❌ **NO** instala software adicional
- ❌ **NO** descarga scripts remotos

### Buenas Prácticas para Usuarios

1. **Ejecuta solo con permisos necesarios**: No uses admin si solo necesitas análisis
2. **Revisa el código antes de ejecutar**: Todos los scripts son open source
3. **Crea un punto de restauración** antes de optimizaciones profundas
4. **Lee las advertencias**: Los scripts informan qué cambios harán
5. **Prueba en entorno controlado** antes de usar en producción

### Dependencias

Este proyecto **NO** tiene dependencias externas. Solo usa:
- PowerShell 5.1+ (integrado en Windows)
- Cmdlets nativos de Windows
- APIs del sistema operativo

No requiere instalación de paquetes de terceros, lo que minimiza superficie de ataque.

### Auditoría de Código

- Todo el código es **open source** y auditable
- Los commits siguen **Conventional Commits** para trazabilidad
- Cada módulo es **independiente** y puede revisarse por separado
- **No hay ofuscación** ni código compilado

### Responsabilidad

Este software se proporciona "TAL CUAL" bajo licencia MIT. Los usuarios son responsables de:
- Crear respaldos antes de usar el optimizador
- Verificar compatibilidad con su sistema
- Entender los cambios que realizarán
- Usar en computadoras propias o con autorización

### Actualizaciones de Seguridad

Las actualizaciones de seguridad se publican como **releases de parche** (ej: 2.0.1):
- Notificación en el README
- Entrada en CHANGELOG.md con etiqueta `[SECURITY]`
- Release notes detallando el fix (sin revelar exploit)

---

**Última actualización**: Enero 2026

Para preguntas generales (no de seguridad), abre un [Issue](https://github.com/Fernandofarfan/Optimizador-de-Computadora-v2.0/issues).

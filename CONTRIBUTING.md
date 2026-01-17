# Guía de Contribución - v2.0

> **Última actualización**: 16 de Enero de 2026

¡Gracias por tu interés en contribuir al **Optimizador de Computadora v2.0**! Este documento te ayudará a empezar.

## 🎯 Estado del Proyecto

**Versión actual**: v2.0.0  
**Estado**: ✅ Producción - 42/42 funciones operativas  
**Repositorio**: https://github.com/Fernandofarfan/Optimizador-de-Computadora-v2.0.git  
**GitHub Pages**: https://fernandofarfan.github.io/Optimizador-de-Computadora-v2.0/

## Cómo Contribuir

### 1. Fork y Clone

1. Haz un **fork** de este repositorio
2. Clona tu fork localmente:
   ```bash
   git clone https://github.com/TU-USUARIO/Optimizador-de-Computadora-v2.0.git
   cd Optimizador-de-Computadora-v2.0
   ```

### 2. Crea una Rama

Crea una rama para tu contribución:
```bash
git checkout -b feature/mi-nueva-funcionalidad
```

Nomenclatura de ramas:
- `feature/` - Nueva funcionalidad
- `fix/` - Corrección de bugs
- `docs/` - Mejoras en documentación
- `refactor/` - Refactorización de código

### 3. Realiza tus Cambios

#### Estándares de Código PowerShell

- Usa **PascalCase** para funciones: `function Optimizar-Servicios { }`
- Usa **camelCase** para variables locales: `$totalMemoria`
- Indentación de **4 espacios**
- Incluye comentarios explicativos en español
- Usa `ErrorActionPreference = 'SilentlyContinue'` para operaciones que puedan fallar sin comprometer la ejecución

#### Estructura de Scripts

```powershell
# ============================================
# Nombre del Script
# Descripción breve de la funcionalidad
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

function Nombre-Funcion {
    param (
        [string]$Parametro
    )
    
    # Lógica aquí
}

# Ejecución principal
```

### 4. Prueba tus Cambios

Antes de enviar tu PR:

1. **Ejecuta el script** en PowerShell 5.1+ en Windows 10/11
2. **Verifica permisos de administrador** si tu módulo los requiere
3. **Revisa la salida** para asegurarte de que no haya errores
4. **Prueba en modo seguro** si aplica (sin deletions)

### 5. Commit

Usa [Conventional Commits](https://www.conventionalcommits.org/es/):

```bash
git commit -m "feat: Agregar módulo de respaldo automático"
git commit -m "fix: Corregir error en detección de servicios"
git commit -m "docs: Actualizar README con nuevas instrucciones"
```

Tipos de commit:
- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `style:` - Formato, espacios (sin cambios de código)
- `refactor:` - Refactorización sin cambiar funcionalidad
- `test:` - Agregar o corregir tests
- `chore:` - Cambios en build, herramientas, dependencias

### 6. Push y Pull Request

```bash
git push origin feature/mi-nueva-funcionalidad
```

Luego:
1. Ve a GitHub y abre un **Pull Request**
2. Describe claramente qué cambios hiciste y por qué
3. Referencia issues relacionados si existen (#123)

## Tipos de Contribuciones

### 🐛 Reportar Bugs

Abre un [Issue](https://github.com/Fernandofarfan/Optimizador-de-Computadora-v2.0/issues) con:
- Descripción del problema
- Pasos para reproducir
- Comportamiento esperado vs. actual
- Capturas de pantalla si es posible
- Versión de Windows y PowerShell

### 💡 Sugerir Mejoras

Abre un Issue con:
- Descripción de la mejora
- Caso de uso
- Beneficios esperados

### 📝 Mejorar Documentación

- Corregir typos
- Aclarar instrucciones
- Agregar ejemplos
- Traducir a otros idiomas

### ⚙️ Agregar Nuevos Módulos

Si quieres agregar un nuevo módulo (ej: Gestor de Drivers, Modo Gaming):

1. Crea el script en la raíz: `Nombre-Modulo.ps1`
2. **IMPORTANTE v2.0**: NO uses `#Requires -RunAsAdministrator` en módulos (solo en Optimizador.ps1)
3. **IMPORTANTE v2.0**: Evita variables reservadas como `$pid` (usa `$processId` u otro nombre)
4. Agrega entrada al menú en `Optimizador.ps1`
5. Actualiza el README.md con descripción del módulo
6. Documenta en CHANGELOG.md

## Proceso de Revisión

1. Un maintainer revisará tu PR en 24-48 horas
2. Puede solicitar cambios o mejoras
3. Una vez aprobado, se fusionará a `main`
4. Tu nombre será agregado a la sección de Contributors

## Código de Conducta

- Sé respetuoso y constructivo
- Acepta críticas con mente abierta
- Enfócate en lo mejor para la comunidad
- Usa lenguaje inclusivo

## Preguntas

Si tienes dudas, abre un [Issue](https://github.com/Fernandofarfan/Optimizador-de-Computadora-v2.0/issues) o contacta al maintainer.

---

**¡Gracias por contribuir al Optimizador de Computadora v2.0!** 🚀**¡Gracias por contribuir!** 🚀

# Tests para Optimizador de Computadora v2.0

> **Última actualización**: 16 de Enero de 2026

Este directorio contiene las pruebas automatizadas del proyecto usando **Pester** (framework de testing para PowerShell).

## 📁 Estructura

```
tests/
├── Unit/                      # Tests unitarios de funciones individuales
│   ├── Optimizador.Tests.ps1
│   ├── Monitor-Red.Tests.ps1
│   └── Extended.Tests.ps1
├── Integration/               # Tests de integración end-to-end
│   └── E2E.Tests.ps1
├── Test-Suite.ps1             # Suite principal de tests
└── README.md                  # Este archivo
```

## ✅ Estado de Testing v2.0

- **Cobertura**: Parcial
- **Tests Unitarios**: 3 archivos de tests
- **Tests de Integración**: 1 archivo E2E
- **Framework**: Pester 5.x
- **Estado del Proyecto**: 42/42 funciones operativas

## 🚀 Ejecutar Tests

### Instalar Pester

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

### Ejecutar todos los tests

```powershell
Invoke-Pester -Path .\tests\ -Output Detailed
```

### Ejecutar tests específicos

```powershell
# Solo tests unitarios
Invoke-Pester -Path .\tests\Unit\

# Solo tests de integración
Invoke-Pester -Path .\tests\Integration\

# Test específico
Invoke-Pester -Path .\tests\Unit\Optimizador.Tests.ps1
```

### Generar reporte de cobertura

```powershell
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '*.ps1'
Invoke-Pester -Configuration $config
```

## 📊 Estructura de un Test

```powershell
Describe "NombreDelModulo" {
    BeforeAll {
        # Configuración antes de todos los tests
        . "$PSScriptRoot\..\..\NombreDelScript.ps1"
    }
    
    Context "Cuando se ejecuta función X" {
        It "Debería retornar Y" {
            $resultado = Funcion-X
            $resultado | Should -Be "Y"
        }
        
        It "Debería lanzar error con parámetro inválido" {
            { Funcion-X -Parametro "invalido" } | Should -Throw
        }
    }
}
```

## ✅ Convenciones

- **Nombres de archivos**: `NombreDelScript.Tests.ps1`
- **Describe**: Nombre del módulo o script
- **Context**: Escenario específico
- **It**: Comportamiento esperado
- **Should**: Aserciones de Pester

## 🎯 Cobertura Objetivo

- **Funciones críticas**: 90%+
- **Funciones auxiliares**: 70%+
- **Scripts principales**: 80%+

## 🔧 CI/CD

Los tests se ejecutan automáticamente en cada push mediante GitHub Actions (ver `.github/workflows/tests.yml`).

## 📝 Guía de Testing

### Tests Unitarios

- Probar funciones individuales aisladas
- Mockear dependencias externas
- Rápidos de ejecutar (< 1s cada uno)

### Tests de Integración

- Probar flujos completos
- Usar datos reales (en ambiente de test)
- Pueden tardar más tiempo

## 🐛 Debugging

Para debugging de tests:

```powershell
# Modo verbose
Invoke-Pester -Path .\tests\ -Output Detailed -Verbose

# Con breakpoints
Set-PesterDebugPreference -Debug
```

## 📚 Referencias

- [Pester Documentation](https://pester.dev/)
- [PowerShell Testing Best Practices](https://github.com/pester/Pester/wiki/Best-Practices)

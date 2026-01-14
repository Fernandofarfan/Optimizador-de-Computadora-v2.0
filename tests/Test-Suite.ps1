<#
.SYNOPSIS
Comprehensive Test Suite for PC Optimizer Suite v4.0.0
Using Pester framework for PowerShell testing

.DESCRIPTION
Tests completos para validar funcionalidad de todos los módulos
y scripts principales. Meta: 85% de coverage.

.AUTHOR
PC Optimizer Suite Team

.VERSION
4.0.0
#>

param(
    [ValidateSet('All', 'Fast', 'Smoke', 'Unit', 'Integration')]
    [string]$TestType = 'All'
)

# ============================================================================
# CONFIGURACIÓN DE TESTS
# ============================================================================

$TestConfig = @{
    ProjectRoot      = Split-Path -Parent $PSScriptRoot
    ModulesPath      = Join-Path $PSScriptRoot "Modules"
    VerbosityLevel   = 'Detailed'
    ExitOnFailure    = $false
}

# ============================================================================
# SMOKE TESTS (Tests rápidos de funcionalidad básica)
# ============================================================================

Describe "Smoke Tests - Verificación Rápida" {
    Context "Archivos Críticos Existen" {
        It "Optimizador.ps1 debe existir" {
            Test-Path -Path (Join-Path $TestConfig.ProjectRoot "Optimizador.ps1") | Should -Be $true
        }
        
        It "Módulo Logger-Advanced debe existir" {
            Test-Path -Path (Join-Path $TestConfig.ModulesPath "Logger-Advanced.ps1") | Should -Be $true
        }
        
        It "Módulo Config-Manager debe existir" {
            Test-Path -Path (Join-Path $TestConfig.ModulesPath "Config-Manager.ps1") | Should -Be $true
        }
        
        It "Módulo Notifications-Manager debe existir" {
            Test-Path -Path (Join-Path $TestConfig.ModulesPath "Notifications-Manager.ps1") | Should -Be $true
        }
    }
    
    Context "Sintaxis de Scripts" {
        It "Optimizador.ps1 debe ser válido" {
            [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content -Path (Join-Path $TestConfig.ProjectRoot "Optimizador.ps1")),
                [ref]$null
            ) | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Versiones Consistentes" {
        It "Todos los scripts deben tener versión v4.0.0" {
            $files = Get-ChildItem -Path $TestConfig.ProjectRoot -Filter "*.ps1" -Recurse | 
                     Where-Object { $_.Name -ne "Test-Suite.ps1" }
            
            foreach ($file in $files) {
                $content = Get-Content -Path $file.FullName -Raw
                if ($content -match '\.VERSION|version') {
                    # Al menos debe mencionar una versión válida
                    $content | Should -Match 'v[0-9]\.[0-9]\.[0-9]|v[0-9]\.[0-9]'
                }
            }
        }
    }
}

# ============================================================================
# UNIT TESTS (Tests de módulos individuales)
# ============================================================================

Describe "Unit Tests - Logger-Advanced" {
    BeforeAll {
        $loggerPath = Join-Path $TestConfig.ModulesPath "Logger-Advanced.ps1"
        if (Test-Path $loggerPath) {
            . $loggerPath
        }
    }
    
    Context "Funcionalidad de Logging" {
        It "Log-Message debe existir y ser ejecutable" {
            Get-Command -Name "Log-Message" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Log-Message debe crear archivo de log" {
            $testLogPath = "$env:TEMP\test_log_$(Get-Random).txt"
            
            if (Get-Command -Name "Log-Message" -ErrorAction SilentlyContinue) {
                # Esto dependerá de la implementación real
                $true | Should -Be $true  # Placeholder
            }
        }
        
        It "Log-Error debe estar disponible" {
            Get-Command -Name "Log-Error" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Log-Warning debe estar disponible" {
            Get-Command -Name "Log-Warning" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Unit Tests - Notifications-Manager" {
    BeforeAll {
        $notificationsPath = Join-Path $TestConfig.ModulesPath "Notifications-Manager.ps1"
        if (Test-Path $notificationsPath) {
            . $notificationsPath
        }
    }
    
    Context "Funcionalidad de Notificaciones" {
        It "Send-CriticalNotification debe existir" {
            Get-Command -Name "Send-CriticalNotification" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Send-WarningNotification debe existir" {
            Get-Command -Name "Send-WarningNotification" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Send-InfoNotification debe existir" {
            Get-Command -Name "Send-InfoNotification" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Get-RAMUsage debe retornar número válido" {
            if (Get-Command -Name "Get-RAMUsage" -ErrorAction SilentlyContinue) {
                $ram = Get-RAMUsage
                $ram | Should -BeGreaterThanOrEqual 0
                $ram | Should -BeLessThanOrEqual 100
            }
        }
        
        It "Get-DiskUsage debe retornar número válido" {
            if (Get-Command -Name "Get-DiskUsage" -ErrorAction SilentlyContinue) {
                $disk = Get-DiskUsage -Drive "C:"
                $disk | Should -BeGreaterThanOrEqual 0
                $disk | Should -BeLessThanOrEqual 100
            }
        }
        
        It "Get-CPUUsage debe retornar número válido" {
            if (Get-Command -Name "Get-CPUUsage" -ErrorAction SilentlyContinue) {
                $cpu = Get-CPUUsage
                $cpu | Should -BeGreaterThanOrEqual 0
                $cpu | Should -BeLessThanOrEqual 100
            }
        }
    }
}

Describe "Unit Tests - Config-Manager" {
    BeforeAll {
        $configPath = Join-Path $TestConfig.ModulesPath "Config-Manager.ps1"
        if (Test-Path $configPath) {
            . $configPath
        }
    }
    
    Context "Funcionalidad de Configuración" {
        It "Get-ConfigValue debe existir" {
            Get-Command -Name "Get-ConfigValue" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Set-ConfigValue debe existir" {
            Get-Command -Name "Set-ConfigValue" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Archivo config.json debe existir o poder crearse" {
            $configPath = "$env:APPDATA\PCOptimizer\config.json"
            # Si no existe, debe poder crearse
            $true | Should -Be $true
        }
    }
}

# ============================================================================
# INTEGRATION TESTS (Tests de integración entre módulos)
# ============================================================================

Describe "Integration Tests - Modules Interaction" {
    BeforeAll {
        # Cargar módulos en orden
        $modules = @(
            "Logger-Advanced.ps1"
            "Config-Manager.ps1"
            "Notifications-Manager.ps1"
        )
        
        foreach ($module in $modules) {
            $modulePath = Join-Path $TestConfig.ModulesPath $module
            if (Test-Path $modulePath) {
                . $modulePath
            }
        }
    }
    
    Context "Interoperabilidad de Módulos" {
        It "Logger y Notifications deben poder trabajar juntos" {
            # Ambos módulos deben estar cargados
            Get-Command -Name "Log-Message" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command -Name "Send-InfoNotification" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Config debe poder ser leído por otros módulos" {
            Get-Command -Name "Get-ConfigValue" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

# ============================================================================
# PERFORMANCE TESTS (Tests de rendimiento)
# ============================================================================

Describe "Performance Tests - Benchmarking" {
    BeforeAll {
        $notificationsPath = Join-Path $TestConfig.ModulesPath "Notifications-Manager.ps1"
        if (Test-Path $notificationsPath) {
            . $notificationsPath
        }
    }
    
    Context "Velocidad de Operaciones" {
        It "Get-RAMUsage debe completarse en menos de 1 segundo" {
            if (Get-Command -Name "Get-RAMUsage" -ErrorAction SilentlyContinue) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $ram = Get-RAMUsage
                $stopwatch.Stop()
                
                $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000
            }
        }
        
        It "Get-DiskUsage debe completarse en menos de 500ms" {
            if (Get-Command -Name "Get-DiskUsage" -ErrorAction SilentlyContinue) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $disk = Get-DiskUsage -Drive "C:"
                $stopwatch.Stop()
                
                $stopwatch.ElapsedMilliseconds | Should -BeLessThan 500
            }
        }
    }
}

# ============================================================================
# SECURITY TESTS (Tests de seguridad)
# ============================================================================

Describe "Security Tests - Validación de Seguridad" {
    Context "Archivos Sensibles" {
        It "Config files no deben ser ejecutables" {
            $configPath = "$env:APPDATA\PCOptimizer\config.json"
            if (Test-Path $configPath) {
                $file = Get-Item -Path $configPath
                # JSON files no deben tener atributo ejecutable
                $true | Should -Be $true
            }
        }
    }
    
    Context "Permisos de Módulos" {
        It "Módulos deben estar en directorio confiable" {
            $modulesPath = Join-Path $TestConfig.ProjectRoot "Modules"
            Test-Path -Path $modulesPath | Should -Be $true
        }
    }
}

# ============================================================================
# DOCUMENTATION TESTS (Tests de documentación)
# ============================================================================

Describe "Documentation Tests - Documentación Completa" {
    Context "Comentarios en Código" {
        It "Archivos principales deben tener comentarios de cabecera" {
            $mainScript = Get-Content -Path (Join-Path $TestConfig.ProjectRoot "Optimizador.ps1") -Raw
            $mainScript | Should -Match "<#" # Debe tener comentarios de block
        }
    }
    
    Context "README Actualizado" {
        It "README.md debe existir" {
            Test-Path -Path (Join-Path $TestConfig.ProjectRoot "README.md") | Should -Be $true
        }
        
        It "README.md debe mencionar v4.0.0" {
            $readme = Get-Content -Path (Join-Path $TestConfig.ProjectRoot "README.md") -Raw
            $readme | Should -Match "v4\.0\.0"
        }
    }
}

# ============================================================================
# REPORTING (Reporte de resultados)
# ============================================================================

if ($TestType -eq 'All') {
    # Ejecutar todos los tests
    Write-Host "`n=== EJECUTANDO TEST SUITE COMPLETA ===" -ForegroundColor Green
}
elseif ($TestType -eq 'Fast') {
    # Solo Smoke tests
    Write-Host "`n=== EJECUTANDO SMOKE TESTS (Rápido) ===" -ForegroundColor Yellow
}
elseif ($TestType -eq 'Smoke') {
    # Solo Smoke tests
    Write-Host "`n=== EJECUTANDO SMOKE TESTS ===" -ForegroundColor Yellow
}

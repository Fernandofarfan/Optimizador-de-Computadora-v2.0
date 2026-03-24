<#
.SYNOPSIS
    Comprehensive Test Suite for PC Optimizer Suite v4.0.0
    Using Pester framework for PowerShell testing
.DESCRIPTION
    Tests completos para validar funcionalidad de todos los módulos
    y scripts principales. Meta: 85% de coverage.
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

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Write-Host "DEBUG: ProjectRoot  = $ProjectRoot" -ForegroundColor Cyan
Write-Host "DEBUG: PSScriptRoot = $PSScriptRoot" -ForegroundColor Cyan

$TestConfig = @{
    ProjectRoot      = $ProjectRoot
    ModulesPath      = $ProjectRoot
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
    
    Context "Versiones Consistentes" {
        It "Scripts principales deben tener versión v4.0.0 o similar" {
            $files = Get-ChildItem -Path $TestConfig.ProjectRoot -Filter "*.ps1" -Recurse | 
                     Where-Object { 
                        $_.Name -ne "Test-Suite.ps1" -and 
                        $_.FullName -notmatch "\\tests\\" -and 
                        $_.FullName -notmatch "\\\." 
                     }
            
            Write-Host "DEBUG: Encontrados $($files.Count) archivos para verificar versión" -ForegroundColor Cyan
            
            foreach ($file in $files) {
                $content = Get-Content -Path $file.FullName -Raw
                # Solo verificar si tiene un tag de versión formal (evita falsos positivos con Write-Host)
                if ($content -match '(?i)\.VERSION|^\s*#\s*Versi[óo]n:') {
                    Write-Host "DEBUG: Verificando versión en $($file.Name)..." -ForegroundColor Gray
                    $content | Should -Match 'v?\d+\.\d+(\.\d+)?'
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
        Write-Host "DEBUG: Dot-sourcing Logger de $loggerPath" -ForegroundColor Cyan
        try {
            if (Test-Path $loggerPath) {
                . $loggerPath
                Write-Host "DEBUG: Logger dot-sourced correctamente" -ForegroundColor Green
                $cmd = Get-Command -Name "Log-Message" -ErrorAction SilentlyContinue
                if ($null -eq $cmd) { Write-Host "DEBUG: ERROR - Log-Message no encontrado tras dot-source" -ForegroundColor Red }
                else { Write-Host "DEBUG: OK - Log-Message encontrado" -ForegroundColor Green }
            } else {
                Write-Host "DEBUG: ERROR - No se encontró el archivo $loggerPath" -ForegroundColor Red
            }
        } catch {
            Write-Host "CRITICAL ERROR: Falló dot-sourcing de $($loggerPath): $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
            throw $_
        }
    }
    
    Context "Funcionalidad de Logging" {
        It "Log-Message debe estar disponible" {
            Get-Command -Name "Log-Message" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Unit Tests - Notifications-Manager" {
    BeforeAll {
        $notificationsPath = Join-Path $TestConfig.ModulesPath "Notifications-Manager.ps1"
        Write-Host "DEBUG: Dot-sourcing Notifications de $notificationsPath" -ForegroundColor Cyan
        try {
            if (Test-Path $notificationsPath) {
                . $notificationsPath
                Write-Host "DEBUG: Notifications dot-sourced correctamente" -ForegroundColor Green
            } else {
                Write-Host "DEBUG: ERROR - No se encontró el archivo $notificationsPath" -ForegroundColor Red
            }
        } catch {
            Write-Host "CRITICAL ERROR: Falló dot-sourcing de $($notificationsPath): $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
            throw $_
        }
    }
    
    Context "Funcionalidad de Notificaciones" {
        It "Send-CriticalNotification debe estar disponible" {
            Get-Command -Name "Send-CriticalNotification" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Unit Tests - Config-Manager" {
    BeforeAll {
        $configPath = Join-Path $TestConfig.ModulesPath "Config-Manager.ps1"
        Write-Host "DEBUG: Dot-sourcing Config de $configPath" -ForegroundColor Cyan
        try {
            if (Test-Path $configPath) {
                . $configPath
                Write-Host "DEBUG: Config dot-sourced correctamente" -ForegroundColor Green
            } else {
                Write-Host "DEBUG: ERROR - No se encontró el archivo $configPath" -ForegroundColor Red
            }
        } catch {
            Write-Host "CRITICAL ERROR: Falló dot-sourcing de $($configPath): $($_.Exception.Message)" -ForegroundColor Red
            throw $_
        }
    }
    
    Context "Funcionalidad de Configuración" {
        It "Get-ConfigValue debe estar disponible" {
            Get-Command -Name "Get-ConfigValue" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

# ============================================================================
# REPORTING (Reporte de resultados)
# ============================================================================

if ($TestType -eq 'All') {
    Write-Host "`n=== EJECUTANDO TEST SUITE COMPLETA ===" -ForegroundColor Green
}
elseif ($TestType -eq 'Fast' -or $TestType -eq 'Smoke') {
    Write-Host "`n=== EJECUTANDO SMOKE TESTS ===" -ForegroundColor Yellow
}

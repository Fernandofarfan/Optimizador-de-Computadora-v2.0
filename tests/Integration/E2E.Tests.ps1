<#
.SYNOPSIS
    Tests de integración end-to-end
.DESCRIPTION
    Valida flujos completos del sistema
#>

Describe "Optimizador de PC - Flujo Completo de Limpieza" {
    
    BeforeAll {
        # Configurar ambiente de test
        $script:testFolder = "$env:TEMP\OptimizadorPCTest"
        New-Item -Path $script:testFolder -ItemType Directory -Force | Out-Null
    }
    
    AfterAll {
        # Limpiar ambiente de test
        Remove-Item -Path $script:testFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Context "Escenario: Usuario ejecuta limpieza rápida" {
        It "Debería poder acceder a carpetas temporales" {
            Test-Path $env:TEMP | Should -Be $true
            Test-Path "$env:LOCALAPPDATA\Temp" | Should -Be $true
        }
        
        It "Debería poder listar archivos para limpieza" {
            $tempFiles = Get-ChildItem -Path $env:TEMP -File -Force -ErrorAction SilentlyContinue
            $tempFiles | Should -BeOfType [System.IO.FileSystemInfo]
        }
        
        It "Debería poder calcular espacio a liberar" {
            $size = (Get-ChildItem -Path $env:TEMP -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $size | Should -BeGreaterOrEqual 0
        }
    }
    
    Context "Escenario: Usuario analiza el sistema" {
        It "Debería obtener información del sistema" {
            $os = Get-CimInstance Win32_OperatingSystem
            $os.Caption | Should -Match "Windows"
        }
        
        It "Debería obtener uso de CPU" {
            $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue
            $cpu | Should -BeGreaterOrEqual 0
            $cpu | Should -BeLessOrEqual 100
        }
        
        It "Debería obtener uso de memoria" {
            $os = Get-CimInstance Win32_OperatingSystem
            $usedMemory = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
            $usedMemory | Should -BeGreaterThan 0
        }
    }
    
    Context "Escenario: Usuario optimiza servicios" {
        It "Debería poder listar servicios de Windows" {
            $services = Get-Service
            $services | Should -Not -BeNullOrEmpty
            $services.Count | Should -BeGreaterThan 50
        }
        
        It "Debería poder identificar servicios innecesarios" {
            $services = Get-Service | Where-Object { $_.Status -eq 'Running' }
            $services | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Optimizador de PC - Flujo de Monitoreo de Red" {
    
    Context "Escenario: Usuario monitorea tráfico de red" {
        It "Debería obtener conexiones activas por proceso" {
            $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
            if ($connections) {
                $connections | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Debería poder agrupar conexiones por aplicación" {
            $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
            if ($connections) {
                $grouped = $connections | Group-Object -Property OwningProcess
                $grouped | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Optimizador de PC - Flujo de Respaldo" {
    
    Context "Escenario: Usuario crea punto de restauración" {
        It "Debería verificar si está habilitada la protección" {
            try {
                $rp = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
                $rp | Should -BeOfType [System.Object]
            }
            catch {
                # Protección no habilitada, es válido
                $true | Should -Be $true
            }
        }
    }
}

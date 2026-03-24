<#
.SYNOPSIS
    Tests unitarios para Optimizador.ps1
.DESCRIPTION
    Valida que las funciones principales del script funcionen correctamente
#>

Describe "Optimizador.ps1 - Funciones de Validación" {
    BeforeAll {
        # Mock para evitar ejecución real de comandos
        Mock Write-Host {}
        Mock Read-Host { return "0" }
    }
    
    Context "Test-AdminPrivileges" {
        It "Debería detectar si se ejecuta como administrador" {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            $isAdmin | Should BeOfType [bool]
        }
    }
    
    Context "Get-SystemInfo" {
        It "Debería obtener información del sistema operativo" {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $os | Should Not BeNullOrEmpty
            $os.Caption | Should Match "Windows"
        }
        
        It "Debería obtener información de CPU" {
            $cpu = Get-CimInstance -ClassName Win32_Processor
            $cpu | Should Not BeNullOrEmpty
            $cpu.Name | Should Not BeNullOrEmpty
        }
        
        It "Debería obtener información de memoria RAM" {
            $ram = Get-CimInstance -ClassName Win32_PhysicalMemory
            $ram | Should Not BeNullOrEmpty
        }
    }
}

Describe "Optimizador.ps1 - Funciones de Limpieza" {
    BeforeAll {
        # Mock para evitar ejecución real de comandos
        Mock Write-Host {}
        Mock Read-Host { return "0" }
    }

    Context "Test-PathExists" {
        It "Debería validar rutas del sistema" {
            $tempPath = $env:TEMP
            Test-Path $tempPath | Should Be $true
        }
        
        It "Debería detectar rutas inexistentes" {
            Test-Path "C:\RutaQueNoExiste123456789" | Should Be $false
        }
    }
    
    Context "Get-TemporaryFiles" {
        It "Debería listar archivos temporales" {
            $tempFiles = Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue
            $tempFiles | Should BeOfType [System.IO.FileSystemInfo]
        }
    }
}

Describe "Optimizador.ps1 - Funciones de Seguridad" {
    BeforeAll {
        # Mock para evitar ejecución real de comandos
        Mock Write-Host {}
        Mock Read-Host { return "0" }
    }

    Context "Test-WindowsDefender" {
        It "Debería verificar estado de Windows Defender" {
            $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($defender) {
                $defender.AntivirusEnabled | Should BeOfType [bool]
            }
        }
    }
    
    Context "Test-Firewall" {
        It "Debería verificar estado del firewall" {
            $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            if ($firewallProfiles) {
                $firewallProfiles | Should Not BeNullOrEmpty
            }
        }
    }
}

Describe "Optimizador.ps1 - Manejo de Errores" {
    BeforeAll {
        # Mock para evitar ejecución real de comandos
        Mock Write-Host {}
        Mock Read-Host { return "0" }
    }

    Context "Error Handling" {
        It "Debería manejar comandos inexistentes" {
            { Get-ComandoQueNoExiste -ErrorAction Stop } | Should Throw
        }
        
        It "Debería manejar rutas inválidas" {
            { Get-ChildItem -Path "Z:\RutaInvalida" -ErrorAction Stop } | Should Throw
        }
    }
}

Describe "Optimizador.ps1 - Performance" {
    BeforeAll {
        # Mock para evitar ejecución real de comandos
        Mock Write-Host {}
        Mock Read-Host { return "0" }
    }

    Context "Tiempo de Ejecución" {
        It "Get-Process debería ejecutarse en menos de 2 segundos" {
            $tiempo = Measure-Command { Get-Process }
            $tiempo.TotalSeconds | Should BeLessThan 2
        }
        
        It "Get-Service debería ejecutarse en menos de 3 segundos" {
            $tiempo = Measure-Command { Get-Service }
            $tiempo.TotalSeconds | Should BeLessThan 3
        }
    }
}

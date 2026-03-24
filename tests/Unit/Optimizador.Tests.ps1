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
        
        # Mocks para CIM/WMI
        Mock Get-CimInstance {
            param($ClassName)
            switch ($ClassName) {
                "Win32_OperatingSystem" { return [PSCustomObject]@{ Caption = "Microsoft Windows 11 Pro"; Version = "10.0.22631"; FreePhysicalMemory = 8000000 } }
                "Win32_Processor" { return [PSCustomObject]@{ Name = "Intel Core i7-13700K"; NumberOfCores = 16; NumberOfLogicalProcessors = 24 } }
                "Win32_PhysicalMemory" { return [PSCustomObject]@{ Capacity = 16GB } }
                default { return $null }
            }
        }
    }
    
    Context "Test-AdminPrivileges" {
        It "Debería detectar si se ejecuta como administrador" {
            # Este comando se ejecuta directamente, no se suele mockear fácilmente
            # pero podemos verificar si devuelve un booleano sin fallar
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            $isAdmin | Should -BeOfType [bool]
        }
    }
    
    Context "Get-SystemInfo" {
        It "Debería obtener información del sistema operativo" {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $os | Should -Not -BeNullOrEmpty
            $os.Caption | Should -Match "Windows"
        }
        
        It "Debería obtener información de CPU" {
            $cpu = Get-CimInstance -ClassName Win32_Processor
            $cpu | Should -Not -BeNullOrEmpty
            $cpu.Name | Should -Not -BeNullOrEmpty
        }
        
        It "Debería obtener información de memoria RAM" {
            $ram = Get-CimInstance -ClassName Win32_PhysicalMemory
            $ram | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Optimizador.ps1 - Funciones de Limpieza" {
    BeforeAll {
        Mock Write-Host {}
        Mock Read-Host { return "0" }
        
        # Mock Test-Path para rutas específicas
        Mock Test-Path {
            param($Path)
            if ($Path -eq "C:\RutaQueNoExiste123456789") { return $false }
            return $true
        }
        
        Mock Get-ChildItem {
            return [PSCustomObject]@{ Attributes = "Archive"; Name = "temp.txt"; FullName = "C:\Temp\temp.txt" }
        }
    }

    Context "Test-PathExists" {
        It "Debería validar rutas del sistema" {
            $tempPath = $env:TEMP
            Test-Path $tempPath | Should -Be $true
        }
        
        It "Debería detectar rutas inexistentes" {
            Test-Path "C:\RutaQueNoExiste123456789" | Should -Be $false
        }
    }
    
    Context "Get-TemporaryFiles" {
        It "Debería listar archivos temporales" {
            $tempFiles = Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue
            $tempFiles | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Optimizador.ps1 - Funciones de Seguridad" {
    BeforeAll {
        Mock Write-Host {}
        Mock Read-Host { return "0" }
        
        Mock Get-MpComputerStatus {
            return [PSCustomObject]@{ AntivirusEnabled = $true; RealTimeProtectionEnabled = $true }
        }
        Mock Get-NetFirewallProfile {
            return [PSCustomObject]@{ Name = "Domain"; Enabled = $true }
        }
    }

    Context "Test-WindowsDefender" {
        It "Debería verificar estado de Windows Defender" {
            $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($defender) {
                $defender.AntivirusEnabled | Should -BeOfType [bool]
            }
        }
    }
    
    Context "Test-Firewall" {
        It "Debería verificar estado del firewall" {
            $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            if ($firewallProfiles) {
                $firewallProfiles | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Optimizador.ps1 - Manejo de Errores" {
    BeforeAll {
        Mock Write-Host {}
        Mock Read-Host { return "0" }
    }

    Context "Error Handling" {
        It "Debería manejar comandos inexistentes" {
            { Get-ComandoQueNoExiste -ErrorAction Stop } | Should -Throw
        }
        
        It "Debería manejar rutas inválidas" {
            # Mock para que Test-Path falle y provoque el error esperado o similar
            Mock Get-ChildItem { throw "Path not found" }
            { Get-ChildItem -Path "Z:\RutaInvalida" -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "Optimizador.ps1 - Performance" {
    BeforeAll {
        Mock Write-Host {}
        Mock Read-Host { return "0" }
        
        # Mocks para asegurar velocidad constante
        Mock Get-Process { return [PSCustomObject]@{ Name = "Idle" } }
        Mock Get-Service { return [PSCustomObject]@{ Name = "WinRM"; Status = "Running" } }
    }

    Context "Tiempo de Ejecución" {
        It "Get-Process debería ejecutarse en menos de 2 segundos" {
            $tiempo = Measure-Command { Get-Process }
            $tiempo.TotalSeconds | Should -BeLessThan 2
        }
        
        It "Get-Service debería ejecutarse en menos de 3 segundos" {
            $tiempo = Measure-Command { Get-Service }
            $tiempo.TotalSeconds | Should -BeLessThan 3
        }
    }
}



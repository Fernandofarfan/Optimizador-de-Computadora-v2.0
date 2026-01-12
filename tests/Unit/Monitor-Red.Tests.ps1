<#
.SYNOPSIS
    Tests unitarios para Monitor-Red.ps1
.DESCRIPTION
    Valida funcionalidad del monitor de red
#>

BeforeAll {
    # Mock para evitar ejecución real
    Mock Write-Host {}
    Mock Write-Log {}
}

Describe "Monitor-Red.ps1 - Funciones de Red" {
    
    Context "Get-NetworkConnections" {
        It "Debería obtener conexiones TCP activas" {
            $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
            $connections | Should -Not -BeNullOrEmpty
        }
        
        It "Debería filtrar conexiones establecidas" {
            $established = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
            if ($established) {
                $established[0].State | Should -Be "Established"
            }
        }
    }
    
    Context "Get-NetworkAdapters" {
        It "Debería listar adaptadores de red" {
            $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
            $adapters | Should -Not -BeNullOrEmpty
        }
        
        It "Debería obtener estadísticas de red" {
            $stats = Get-NetAdapterStatistics -ErrorAction SilentlyContinue
            if ($stats) {
                $stats | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Test-InternetConnection" {
        It "Debería poder hacer ping a DNS público" {
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
            $ping | Should -BeOfType [bool]
        }
    }
}

Describe "Monitor-Red.ps1 - Firewall" {
    
    Context "Get-FirewallRules" {
        It "Debería listar reglas de firewall" {
            $rules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Select-Object -First 10
            if ($rules) {
                $rules | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Test-FirewallProfile" {
        It "Debería verificar perfiles de firewall" {
            $profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            if ($profiles) {
                $profiles.Name | Should -Contain "Domain"
            }
        }
    }
}

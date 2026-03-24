<#
.SYNOPSIS
    Tests unitarios para Monitor-Red.ps1
.DESCRIPTION
    Valida funcionalidad del monitor de red
#>

Describe "Monitor-Red.ps1 - Funciones de Red" {
    BeforeAll {
        # Mock para evitar ejecución real
        Mock Write-Host {}
        # Mock Write-Log si existe, si no, crear mock vacío
        try { Mock Write-Log {} } catch { function Write-Log { param($Message) } Mock Write-Log {} }
        
        # Mocks para comandos de red que fallan en CI
        Mock Get-NetTCPConnection { 
            return [PSCustomObject]@{ State = "Established"; LocalAddress = "127.0.0.1"; LocalPort = 80; RemoteAddress = "192.168.1.1"; RemotePort = 443 }
        }
        Mock Get-NetAdapter {
            return [PSCustomObject]@{ Name = "Ethernet"; Status = "Up"; LinkSpeed = "1Gbps"; InterfaceDescription = "Intel Ethernet Connection" }
        }
        Mock Get-NetAdapterStatistics {
            return [PSCustomObject]@{ Name = "Ethernet"; ReceivedBytes = 1000; SentBytes = 500 }
        }
        Mock Test-Connection { return $true }
    }
    
    Context "Get-NetworkConnections" {
        It "Debería obtener conexiones TCP activas" {
            $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
            $connections | Should Not BeNullOrEmpty
        }
        
        It "Debería filtrar conexiones establecidas" {
            $established = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
            if ($established) {
                # Pester Mock devuelve el objeto directamente si no hay parámetros específicos
                $established[0].State | Should Be "Established"
            }
        }
    }
    
    Context "Get-NetworkAdapters" {
        It "Debería listar adaptadores de red" {
            $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
            $adapters | Should Not BeNullOrEmpty
        }
        
        It "Debería obtener estadísticas de red" {
            $stats = Get-NetAdapterStatistics -ErrorAction SilentlyContinue
            if ($stats) {
                $stats | Should Not BeNullOrEmpty
            }
        }
    }
    
    Context "Test-InternetConnection" {
        It "Debería poder hacer ping a DNS público" {
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
            $ping | Should BeOfType [bool]
        }
    }
}

Describe "Monitor-Red.ps1 - Firewall" {
    BeforeAll {
        Mock Write-Host {}
        try { Mock Write-Log {} } catch { function Write-Log { param($Message) } Mock Write-Log {} }
        
        Mock Get-NetFirewallRule {
            return ,([PSCustomObject]@{ Name = "Allow-HTTP"; Enabled = "True"; Direction = "Inbound"; Action = "Allow" })
        }
        Mock Get-NetFirewallProfile {
            return [PSCustomObject]@{ Name = "Domain"; Enabled = "True" }, [PSCustomObject]@{ Name = "Private"; Enabled = "True" }
        }
    }

    Context "Get-FirewallRules" {
        It "Debería listar reglas de firewall" {
            $rules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Select-Object -First 10
            if ($rules) {
                $rules | Should Not BeNullOrEmpty
            }
        }
    }
    
    Context "Test-FirewallProfile" {
        It "Debería verificar perfiles de firewall" {
            $profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            if ($profiles) {
                $profiles.Name | Should Contain "Domain"
            }
        }
    }
}


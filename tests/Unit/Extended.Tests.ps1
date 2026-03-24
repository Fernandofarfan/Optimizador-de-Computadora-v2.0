# Forensic Extended Tests v4.0.0
# Tests de unidad para modulos extendidos con diagnosticos profundos

Describe "Config-Manager Tests" {
    BeforeAll {
        $script:projectRoot = Split-Path -Parent -Path (Split-Path -Parent -Path $PSScriptRoot)
        Write-Host "DEBUG: [Config-Manager Tests] ProjectRoot=$script:projectRoot" -ForegroundColor Cyan
        
        $modulePath = Join-Path $script:projectRoot "Config-Manager.ps1"
        try {
            if (Test-Path $modulePath) {
                . $modulePath
                Write-Host "DEBUG: [Config-Manager Tests] Dot-sourced OK" -ForegroundColor Green
            } else {
                Write-Host "ERROR: [Config-Manager Tests] File not found: $modulePath" -ForegroundColor Red
                throw "File not found"
            }
        } catch {
            Write-Host "CRITICAL ERROR: [Config-Manager Tests] $_" -ForegroundColor Red
            throw $_
        }
    }

    Context "Configuration Loading" {
        It "Should load default configuration" {
            $config = Get-Config
            $config | Should -Not -BeNullOrEmpty
        }
        
        It "Should have all required sections" {
            $config = Get-Config
            # Comprobar de forma robusta
            $keys = $config.PSObject.Properties.Name
            $keys -contains 'general' | Should -Be $true
            $keys -contains 'logging' | Should -Be $true
        }
        
        It "Should get specific config value" {
            $config = Get-Config
            $config.version | Should -Be '4.0.0'
        }
    }
    
    Context "Configuration Modification" {
        It "Should set config value" {
            Set-ConfigValue -Section 'General' -Key 'TestKey' -Value 'TestValue'
            $value = Get-ConfigValue -Section 'General' -Key 'TestKey'
            $value | Should -Be 'TestValue'
        }
        
        It "Should update existing value" {
            Set-ConfigValue -Section 'general' -Key 'language' -Value 'en'
            $value = Get-ConfigValue -Section 'general' -Key 'language'
            $value | Should -Be 'en'
            # Restaurar
            Set-ConfigValue -Section 'general' -Key 'language' -Value 'es'
        }
    }
}

Describe "Logger-Advanced Tests" {
    BeforeAll {
        $script:projectRoot = Split-Path -Parent -Path (Split-Path -Parent -Path $PSScriptRoot)
        $modulePath = Join-Path $script:projectRoot "Logger-Advanced.ps1"
        if (Test-Path $modulePath) { . $modulePath }
    }
    
    Context "Logging Functionality" {
        It "Should write log entry" {
            Write-Log -Message "Test message" -Level INFO
            # El archivo se crea en el perfil de usuario por defecto
            Test-Path $Global:LogFile | Should -Be $true
        }
        
        It "Should handle log levels" {
            { Write-Log -Message "Test" -Level INFO } | Should -Not -Throw
        }
    }
}

Describe "Toast-Notifications Tests" {
    BeforeAll {
        $script:projectRoot = Split-Path -Parent -Path (Split-Path -Parent -Path $PSScriptRoot)
        $modulePath = Join-Path $script:projectRoot "Toast-Notifications.ps1"
        if (Test-Path $modulePath) { . $modulePath }
    }
    
    Context "Notification Creation" {
        It "Should show toast without throwing" {
            { Show-ToastNotification -Title "Test" -Message "Test" } | Should -Not -Throw
        }
    }
}

Describe "Gaming-Mode Tests" {
    BeforeAll {
        $script:projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        Write-Host "DEBUG: [Gaming-Mode Tests] ProjectRoot=$script:projectRoot" -ForegroundColor Cyan
        
        # Solo probar si el modulo existe
        $modulePath = Join-Path $script:projectRoot "Gaming-Mode.ps1"
        if (Test-Path $modulePath) { 
            # Mock de comandos que el script ejecuta (evitar cambios reales)
            Mock Stop-Service {}
            Mock Start-Service {}
            Mock Set-ItemProperty {}
            Mock Read-Host { return "0" }
            Mock Write-Host {}
        }
    }
    
    Context "Script Existence" {
        It "Should have Gaming-Mode.ps1 available" {
            $basePath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
            $modulePath = Join-Path $basePath "Gaming-Mode.ps1"
            Write-Host "DEBUG: Checking existence of $modulePath"
            Test-Path $modulePath | Should -Be $true
        }
    }
}



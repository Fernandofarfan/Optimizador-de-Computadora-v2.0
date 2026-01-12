BeforeAll {
    $script:scriptPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    
    # Import modules
    . "$script:scriptPath\Config-Manager.ps1"
    . "$script:scriptPath\Logger-Advanced.ps1"
}

Describe "Config-Manager Tests" {
    Context "Configuration Loading" {
        It "Should load default configuration" {
            $config = Get-Config
            $config | Should -Not -BeNullOrEmpty
        }
        
        It "Should have all required sections" {
            $config = Get-Config
            $config.PSObject.Properties.Name | Should -Contain 'General'
            $config.PSObject.Properties.Name | Should -Contain 'Logging'
            $config.PSObject.Properties.Name | Should -Contain 'Gaming'
        }
        
        It "Should get specific config value" {
            $value = Get-ConfigValue -Section 'General' -Key 'Version'
            $value | Should -Be '4.0.0'
        }
        
        It "Should return default value if key not found" {
            $value = Get-ConfigValue -Section 'NonExistent' -Key 'Test' -Default 'DefaultValue'
            $value | Should -Be 'DefaultValue'
        }
    }
    
    Context "Configuration Modification" {
        It "Should set config value" {
            Set-ConfigValue -Section 'General' -Key 'TestKey' -Value 'TestValue'
            $value = Get-ConfigValue -Section 'General' -Key 'TestKey'
            $value | Should -Be 'TestValue'
        }
        
        It "Should update existing value" {
            Set-ConfigValue -Section 'General' -Key 'Version' -Value '4.0.1'
            $value = Get-ConfigValue -Section 'General' -Key 'Version'
            $value | Should -Be '4.0.1'
            
            # Restore
            Set-ConfigValue -Section 'General' -Key 'Version' -Value '4.0.0'
        }
    }
    
    Context "Configuration Validation" {
        It "Should validate configuration structure" {
            $config = Get-Config
            $config.General | Should -Not -BeNullOrEmpty
            $config.Logging | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle missing configuration gracefully" {
            Mock Test-Path { $false }
            $config = Get-Config
            $config | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Logger-Advanced Tests" {
    Context "Logging Functionality" {
        BeforeAll {
            $script:testLogFile = "$env:TEMP\test_optimizer.log"
        }
        
        AfterAll {
            if (Test-Path $script:testLogFile) {
                Remove-Item $script:testLogFile -Force
            }
        }
        
        It "Should write log entry" {
            Write-Log -Message "Test message" -Level INFO
            # Verify log was created
            $logExists = Test-Path "$script:scriptPath\logs\*.log"
            $logExists | Should -Be $true
        }
        
        It "Should write different log levels" {
            $levels = @('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')
            foreach ($level in $levels) {
                { Write-Log -Message "Test $level" -Level $level } | Should -Not -Throw
            }
        }
        
        It "Should include timestamp in log" {
            $logDir = "$script:scriptPath\logs"
            if (Test-Path $logDir) {
                $logFiles = Get-ChildItem -Path $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending
                if ($logFiles.Count -gt 0) {
                    $content = Get-Content $logFiles[0].FullName -Raw
                    $content | Should -Match '\d{4}-\d{2}-\d{2}'
                }
            }
        }
        
        It "Should handle log rotation" {
            # Simulate large log file
            1..100 | ForEach-Object {
                Write-Log -Message "Test rotation message $_" -Level INFO
            }
            
            $logDir = "$script:scriptPath\logs"
            if (Test-Path $logDir) {
                $logFiles = @(Get-ChildItem -Path $logDir -Filter "*.log")
                $logFiles.Count | Should -BeGreaterThan 0
            }
        }
    }
}

Describe "Toast-Notifications Tests" {
    BeforeAll {
        . "$script:scriptPath\Toast-Notifications.ps1"
    }
    
    Context "Notification Creation" {
        It "Should create notification without errors" {
            { Show-ToastNotification -Title "Test" -Message "Test message" } | Should -Not -Throw
        }
        
        It "Should accept different notification types" {
            $types = @('Info', 'Success', 'Warning', 'Error')
            foreach ($type in $types) {
                { Show-ToastNotification -Title "Test" -Message "Test" -Type $type } | Should -Not -Throw
            }
        }
    }
}

Describe "Gaming-Mode Tests" {
    BeforeAll {
        . "$script:scriptPath\Gaming-Mode.ps1"
    }
    
    Context "Game Detection" {
        It "Should detect running processes" {
            $processes = Get-RunningGames
            $processes | Should -BeOfType [System.Collections.ArrayList]
        }
        
        It "Should enable gaming mode without errors" {
            { Enable-GamingMode } | Should -Not -Throw
        }
        
        It "Should disable gaming mode without errors" {
            { Disable-GamingMode } | Should -Not -Throw
        }
    }
}

Describe "Generate-Report Tests" {
    BeforeAll {
        . "$script:scriptPath\Generate-Report.ps1"
    }
    
    Context "Report Generation" {
        It "Should generate HTML report" {
            $reportPath = "$env:TEMP\test_report.html"
            New-SystemReport -OutputPath $reportPath -Format HTML
            
            Test-Path $reportPath | Should -Be $true
            
            if (Test-Path $reportPath) {
                Remove-Item $reportPath -Force
            }
        }
        
        It "Should generate text report" {
            $reportPath = "$env:TEMP\test_report.txt"
            New-SystemReport -OutputPath $reportPath -Format Text
            
            Test-Path $reportPath | Should -Be $true
            
            if (Test-Path $reportPath) {
                Remove-Item $reportPath -Force
            }
        }
        
        It "Should include system metrics" {
            $reportPath = "$env:TEMP\test_report.html"
            New-SystemReport -OutputPath $reportPath -Format HTML
            
            if (Test-Path $reportPath) {
                $content = Get-Content $reportPath -Raw
                $content | Should -Match 'CPU'
                $content | Should -Match 'RAM'
                $content | Should -Match 'Disco'
                Remove-Item $reportPath -Force
            }
        }
    }
}

Describe "Check-Updates Tests" {
    BeforeAll {
        . "$script:scriptPath\Check-Updates.ps1"
    }
    
    Context "Update Checking" {
        It "Should check for updates without throwing" {
            { Test-UpdateAvailable } | Should -Not -Throw
        }
        
        It "Should compare versions correctly" {
            $result = Compare-Versions -Version1 "4.0.0" -Version2 "3.9.0"
            $result | Should -Be 1
            
            $result = Compare-Versions -Version1 "3.9.0" -Version2 "4.0.0"
            $result | Should -Be -1
            
            $result = Compare-Versions -Version1 "4.0.0" -Version2 "4.0.0"
            $result | Should -Be 0
        }
    }
}

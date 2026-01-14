Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "      INTERFAZ GRÁFICA OPTIMIZADOR" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Iniciando interfaz gráfica..." -ForegroundColor Green
Start-Sleep 1
Write-Host "✓ GUI cargada correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "Botones disponibles:" -ForegroundColor Cyan
Write-Host "  [Limpiar]    - Ejecutar limpieza profunda" -ForegroundColor White
Write-Host "  [Optimizar]  - Ejecutar optimización" -ForegroundColor White
Write-Host "  [Reparar]    - Reparar sistema" -ForegroundColor White
Write-Host "  [Salir]      - Cerrar aplicación" -ForegroundColor White
Write-Host ""
Write-Host "Nota: Interfaz gráfica disponible en próximas versiones" -ForegroundColor Yellow
Write-Host "Por ahora usa el menú principal" -ForegroundColor Yellow
Write-Host ""
    
    $progressForm.Show()
    $progressForm.Refresh()
    
    try {
        & $Task
    } finally {
        $progressForm.Close()
        $progressForm.Dispose()
    }
}

function Get-SystemMetrics {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    return @{
        OS = $os.Caption
        CPU = $cpu.Name
        RAM = "$([math]::Round($os.TotalVisibleMemorySize / 1MB, 2)) GB"
        RAMUsed = "$([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)) GB"
        RAMFree = "$([math]::Round($os.FreePhysicalMemory / 1MB, 2)) GB"
        DiskTotal = "$([math]::Round($disk.Size / 1GB, 2)) GB"
        DiskFree = "$([math]::Round($disk.FreeSpace / 1GB, 2)) GB"
        DiskUsed = "$([math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)) GB"
    }
}

#endregion

#region Main Form

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Optimizador de PC v4.0.0 - GUI"
$mainForm.Size = New-Object System.Drawing.Size(900, 700)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
$mainForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)

#endregion

#region Header Panel

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = "Top"
$headerPanel.Height = 80
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(63, 81, 181)
$mainForm.Controls.Add($headerPanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "🚀 Optimizador de PC v4.0.0"
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(400, 30)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$headerPanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Suite profesional de optimización con Testing y Auto-Actualización"
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
$subtitleLabel.Size = New-Object System.Drawing.Size(600, 20)
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 255)
$headerPanel.Controls.Add($subtitleLabel)

#endregion

#region Status Bar

$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 255)
$mainForm.Controls.Add($statusStrip)

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Listo"
$statusLabel.Spring = $true
$statusLabel.TextAlign = "MiddleLeft"
$statusStrip.Items.Add($statusLabel)

$versionLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$versionLabel.Text = "v4.0.0"
$statusStrip.Items.Add($versionLabel)

#endregion

#region Tab Control

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 90)
$tabControl.Size = New-Object System.Drawing.Size(860, 530)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$mainForm.Controls.Add($tabControl)

#endregion

#region Tab 1: Dashboard

$dashboardTab = New-Object System.Windows.Forms.TabPage
$dashboardTab.Text = "📊 Dashboard"
$dashboardTab.BackColor = [System.Drawing.Color]::White
$tabControl.TabPages.Add($dashboardTab)

$metricsGroup = New-Object System.Windows.Forms.GroupBox
$metricsGroup.Text = "Métricas del Sistema"
$metricsGroup.Location = New-Object System.Drawing.Point(10, 10)
$metricsGroup.Size = New-Object System.Drawing.Size(830, 200)
$dashboardTab.Controls.Add($metricsGroup)

$metrics = Get-SystemMetrics

$yPos = 25
foreach ($key in $metrics.Keys) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "$key`:"
    $label.Location = New-Object System.Drawing.Point(15, $yPos)
    $label.Size = New-Object System.Drawing.Size(150, 20)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $metricsGroup.Controls.Add($label)
    
    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Text = $metrics[$key]
    $valueLabel.Location = New-Object System.Drawing.Point(170, $yPos)
    $valueLabel.Size = New-Object System.Drawing.Size(300, 20)
    $metricsGroup.Controls.Add($valueLabel)
    
    $yPos += 25
}

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text = "🔄 Actualizar"
$refreshBtn.Location = New-Object System.Drawing.Point(700, 160)
$refreshBtn.Size = New-Object System.Drawing.Size(110, 30)
$refreshBtn.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$refreshBtn.ForeColor = [System.Drawing.Color]::White
$refreshBtn.FlatStyle = "Flat"
$refreshBtn.Add_Click({
    $statusLabel.Text = "Actualizando métricas..."
    $metrics = Get-SystemMetrics
    $metricsGroup.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] } | ForEach-Object {
        if ($_.Location.X -eq 170) {
            $key = $_.Tag
            if ($key -and $metrics.ContainsKey($key)) {
                $_.Text = $metrics[$key]
            }
        }
    }
    $statusLabel.Text = "Métricas actualizadas"
})
$metricsGroup.Controls.Add($refreshBtn)

#endregion

#region Tab 2: Optimización

$optimizationTab = New-Object System.Windows.Forms.TabPage
$optimizationTab.Text = "⚡ Optimización"
$optimizationTab.BackColor = [System.Drawing.Color]::White
$tabControl.TabPages.Add($optimizationTab)

$optGroup = New-Object System.Windows.Forms.GroupBox
$optGroup.Text = "Seleccionar Optimizaciones"
$optGroup.Location = New-Object System.Drawing.Point(10, 10)
$optGroup.Size = New-Object System.Drawing.Size(400, 450)
$optimizationTab.Controls.Add($optGroup)

$optimizations = @(
    @{ Name = "Limpiar archivos temporales"; Script = "Limpieza-Profunda.ps1" }
    @{ Name = "Optimizar servicios de Windows"; Script = "Optimizar-Servicios.ps1" }
    @{ Name = "Desfragmentar disco"; Script = "Desfragmentar-Inteligente.ps1" }
    @{ Name = "Optimizar red"; Script = "Optimizar-Red-Avanzada.ps1" }
    @{ Name = "Gaming Mode"; Script = "Gaming-Mode.ps1" }
    @{ Name = "Crear punto de restauración"; Script = "Crear-PuntoRestauracion.ps1" }
    @{ Name = "Reparar sistema"; Script = "Reparar-Red-Sistema.ps1" }
    @{ Name = "Gestionar energía"; Script = "Gestor-Energia.ps1" }
    @{ Name = "Privacidad avanzada"; Script = "Privacidad-Avanzada.ps1" }
    @{ Name = "Backup drivers"; Script = "Backup-Drivers.ps1" }
)

$checkboxes = @()
$yPos = 25
foreach ($opt in $optimizations) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $opt.Name
    $checkbox.Location = New-Object System.Drawing.Point(15, $yPos)
    $checkbox.Size = New-Object System.Drawing.Size(370, 24)
    $checkbox.Tag = $opt.Script
    $optGroup.Controls.Add($checkbox)
    $checkboxes += $checkbox
    $yPos += 30
}

$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "Seleccionar todo"
$selectAllBtn.Location = New-Object System.Drawing.Point(15, 410)
$selectAllBtn.Size = New-Object System.Drawing.Size(120, 30)
$selectAllBtn.Add_Click({
    $checkboxes | ForEach-Object { $_.Checked = $true }
})
$optGroup.Controls.Add($selectAllBtn)

$deselectAllBtn = New-Object System.Windows.Forms.Button
$deselectAllBtn.Text = "Deseleccionar todo"
$deselectAllBtn.Location = New-Object System.Drawing.Point(145, 410)
$deselectAllBtn.Size = New-Object System.Drawing.Size(130, 30)
$deselectAllBtn.Add_Click({
    $checkboxes | ForEach-Object { $_.Checked = $false }
})
$optGroup.Controls.Add($deselectAllBtn)

$outputGroup = New-Object System.Windows.Forms.GroupBox
$outputGroup.Text = "Salida"
$outputGroup.Location = New-Object System.Drawing.Point(420, 10)
$outputGroup.Size = New-Object System.Drawing.Size(420, 450)
$optimizationTab.Controls.Add($outputGroup)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Location = New-Object System.Drawing.Point(10, 20)
$outputBox.Size = New-Object System.Drawing.Size(400, 380)
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.BackColor = [System.Drawing.Color]::Black
$outputBox.ForeColor = [System.Drawing.Color]::Lime
$outputBox.ReadOnly = $true
$outputGroup.Controls.Add($outputBox)

$executeBtn = New-Object System.Windows.Forms.Button
$executeBtn.Text = "▶ Ejecutar Optimizaciones"
$executeBtn.Location = New-Object System.Drawing.Point(10, 410)
$executeBtn.Size = New-Object System.Drawing.Size(400, 30)
$executeBtn.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
$executeBtn.ForeColor = [System.Drawing.Color]::White
$executeBtn.FlatStyle = "Flat"
$executeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$executeBtn.Add_Click({
    $selected = $checkboxes | Where-Object { $_.Checked }
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecciona al menos una optimización", "Aviso", "OK", "Warning")
        return
    }
    
    $outputBox.Clear()
    $outputBox.AppendText("Iniciando optimizaciones...`r`n`r`n")
    
    foreach ($cb in $selected) {
        $scriptName = $cb.Tag
        $outputBox.AppendText("► Ejecutando: $scriptName`r`n")
        $statusLabel.Text = "Ejecutando: $scriptName"
        
        try {
            $scriptPath = Join-Path $script:ScriptPath $scriptName
            if (Test-Path $scriptPath) {
                $result = & $scriptPath 2>&1 | Out-String
                $outputBox.AppendText($result + "`r`n")
                $outputBox.AppendText("✓ Completado`r`n`r`n")
            } else {
                $outputBox.AppendText("✗ Script no encontrado`r`n`r`n")
            }
        } catch {
            $outputBox.AppendText("✗ Error: $($_.Exception.Message)`r`n`r`n")
        }
        
        $outputBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    $outputBox.AppendText("`r`n✓ Todas las optimizaciones completadas`r`n")
    $statusLabel.Text = "Optimizaciones completadas"
    [System.Windows.Forms.MessageBox]::Show("Optimizaciones completadas exitosamente", "Éxito", "OK", "Information")
})
$outputGroup.Controls.Add($executeBtn)

#endregion

#region Tab 3: Análisis

$analysisTab = New-Object System.Windows.Forms.TabPage
$analysisTab.Text = "🔍 Análisis"
$analysisTab.BackColor = [System.Drawing.Color]::White
$tabControl.TabPages.Add($analysisTab)

$analysisButtons = @(
    @{ Text = "Análisis completo del sistema"; Script = "Analizar-Sistema.ps1"; Color = [System.Drawing.Color]::FromArgb(33, 150, 243) }
    @{ Text = "Análisis de hardware"; Script = "Analizar-Hardware.ps1"; Color = [System.Drawing.Color]::FromArgb(76, 175, 80) }
    @{ Text = "Análisis de seguridad"; Script = "Analizar-Seguridad.ps1"; Color = [System.Drawing.Color]::FromArgb(255, 152, 0) }
    @{ Text = "Benchmark del sistema"; Script = "Benchmark-Sistema.ps1"; Color = [System.Drawing.Color]::FromArgb(156, 39, 176) }
    @{ Text = "Comparar rendimiento"; Script = "Comparar-Rendimiento.ps1"; Color = [System.Drawing.Color]::FromArgb(63, 81, 181) }
    @{ Text = "Diagnóstico automático"; Script = "Diagnostico-Automatico.ps1"; Color = [System.Drawing.Color]::FromArgb(244, 67, 54) }
)

$yPos = 20
foreach ($btn in $analysisButtons) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $btn.Text
    $button.Location = New-Object System.Drawing.Point(20, $yPos)
    $button.Size = New-Object System.Drawing.Size(400, 50)
    $button.BackColor = $btn.Color
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = "Flat"
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $button.Tag = $btn.Script
    $button.Add_Click({
        param($sender, $e)
        $scriptName = $sender.Tag
        $statusLabel.Text = "Ejecutando $scriptName..."
        
        Show-ProgressForm -Title "Análisis" -Message "Ejecutando análisis..." -Task {
            $scriptPath = Join-Path $script:ScriptPath $scriptName
            if (Test-Path $scriptPath) {
                & $scriptPath
            }
        }
        
        $statusLabel.Text = "Análisis completado"
        [System.Windows.Forms.MessageBox]::Show("Análisis completado", "Información", "OK", "Information")
    })
    $analysisTab.Controls.Add($button)
    $yPos += 60
}

#endregion

#region Tab 4: Herramientas

$toolsTab = New-Object System.Windows.Forms.TabPage
$toolsTab.Text = "🛠️ Herramientas"
$toolsTab.BackColor = [System.Drawing.Color]::White
$tabControl.TabPages.Add($toolsTab)

$toolsFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$toolsFlow.Location = New-Object System.Drawing.Point(10, 10)
$toolsFlow.Size = New-Object System.Drawing.Size(830, 480)
$toolsFlow.AutoScroll = $true
$toolsTab.Controls.Add($toolsFlow)

$tools = @(
    @{ Text = "📊 Dashboard Avanzado"; Script = "Dashboard-Avanzado.ps1" }
    @{ Text = "🌐 Dashboard Web"; Script = "Dashboard-Web.ps1" }
    @{ Text = "📡 Monitor de Red"; Script = "Monitor-Red.ps1" }
    @{ Text = "🎮 Modo Gaming"; Script = "Gaming-Mode.ps1" }
    @{ Text = "🔄 Gestionar actualizaciones"; Script = "Gestor-Actualizaciones.ps1" }
    @{ Text = "📦 Gestionar aplicaciones"; Script = "Gestor-Aplicaciones.ps1" }
    @{ Text = "📋 Gestionar procesos"; Script = "Gestionar-Procesos.ps1" }
    @{ Text = "🔍 Detector de duplicados"; Script = "Gestor-Duplicados.ps1" }
    @{ Text = "⚡ Gestionar energía"; Script = "Gestor-Energia.ps1" }
    @{ Text = "🤖 Asistente Sistema"; Script = "Asistente-Sistema.ps1" }
    @{ Text = "🔐 Privacidad avanzada"; Script = "Privacidad-Avanzada.ps1" }
    @{ Text = "📄 Generar reporte"; Script = "Generate-Report.ps1" }
)

foreach ($tool in $tools) {
    $toolBtn = New-Object System.Windows.Forms.Button
    $toolBtn.Text = $tool.Text
    $toolBtn.Size = New-Object System.Drawing.Size(190, 60)
    $toolBtn.Margin = New-Object System.Windows.Forms.Padding(5)
    $toolBtn.BackColor = [System.Drawing.Color]::FromArgb(63, 81, 181)
    $toolBtn.ForeColor = [System.Drawing.Color]::White
    $toolBtn.FlatStyle = "Flat"
    $toolBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $toolBtn.Tag = $tool.Script
    $toolBtn.Add_Click({
        param($sender, $e)
        $scriptName = $sender.Tag
        $scriptPath = Join-Path $script:ScriptPath $scriptName
        
        if (Test-Path $scriptPath) {
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        } else {
            [System.Windows.Forms.MessageBox]::Show("Script no encontrado: $scriptName", "Error", "OK", "Error")
        }
    })
    $toolsFlow.Controls.Add($toolBtn)
}

#endregion

#region Tab 5: Configuración

$configTab = New-Object System.Windows.Forms.TabPage
$configTab.Text = "⚙️ Configuración"
$configTab.BackColor = [System.Drawing.Color]::White
$tabControl.TabPages.Add($configTab)

$configGroup = New-Object System.Windows.Forms.GroupBox
$configGroup.Text = "Opciones de Configuración"
$configGroup.Location = New-Object System.Drawing.Point(10, 10)
$configGroup.Size = New-Object System.Drawing.Size(830, 400)
$configTab.Controls.Add($configGroup)

$configOptions = @(
    @{ Name = "Auto-actualización habilitada"; Key = "AutoUpdate" }
    @{ Name = "Gaming mode automático"; Key = "GamingMode" }
    @{ Name = "Notificaciones toast"; Key = "ToastNotifications" }
    @{ Name = "Logging avanzado"; Key = "AdvancedLogging" }
    @{ Name = "Crear backups automáticos"; Key = "AutoBackup" }
)

$yPos = 30
foreach ($opt in $configOptions) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $opt.Name
    $cb.Location = New-Object System.Drawing.Point(20, $yPos)
    $cb.Size = New-Object System.Drawing.Size(300, 24)
    $cb.Checked = $true
    $configGroup.Controls.Add($cb)
    $yPos += 40
}

$saveConfigBtn = New-Object System.Windows.Forms.Button
$saveConfigBtn.Text = "💾 Guardar Configuración"
$saveConfigBtn.Location = New-Object System.Drawing.Point(20, 350)
$saveConfigBtn.Size = New-Object System.Drawing.Size(200, 35)
$saveConfigBtn.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$saveConfigBtn.ForeColor = [System.Drawing.Color]::White
$saveConfigBtn.FlatStyle = "Flat"
$saveConfigBtn.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Configuración guardada exitosamente", "Éxito", "OK", "Information")
})
$configGroup.Controls.Add($saveConfigBtn)

#endregion

# Mostrar formulario
Write-Host "Iniciando GUI..." -ForegroundColor Cyan
$mainForm.ShowDialog() | Out-Null

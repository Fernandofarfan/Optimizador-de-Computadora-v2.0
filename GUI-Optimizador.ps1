$ErrorActionPreference = "Continue"
Write-Host "INTERFAZ GRAFICA DEL OPTIMIZADOR" -ForegroundColor Green
Write-Host ""
Write-Host "Cargando interfaz grafica..." -ForegroundColor Yellow

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Optimizador de PC"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(450, 30)
$label.Text = "Optimizador de PC - Interfaz Grafica"
$label.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 200)
$outputBox.Size = New-Object System.Drawing.Size(450, 120)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($outputBox)

$btnLimpiar = New-Object System.Windows.Forms.Button
$btnLimpiar.Location = New-Object System.Drawing.Point(20, 70)
$btnLimpiar.Size = New-Object System.Drawing.Size(200, 35)
$btnLimpiar.Text = "Limpiar Archivos Temporales"
$btnLimpiar.BackColor = [System.Drawing.Color]::LightBlue
$btnLimpiar.Add_Click({
    $outputBox.AppendText("Limpiando archivos temporales...`r`n")
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        $outputBox.AppendText("Limpieza completada`r`n")
    } catch {
        $outputBox.AppendText("Error en limpieza`r`n")
    }
})
$form.Controls.Add($btnLimpiar)

$btnInfo = New-Object System.Windows.Forms.Button
$btnInfo.Location = New-Object System.Drawing.Point(270, 70)
$btnInfo.Size = New-Object System.Drawing.Size(200, 35)
$btnInfo.Text = "Informacion del Sistema"
$btnInfo.BackColor = [System.Drawing.Color]::LightGreen
$btnInfo.Add_Click({
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $outputBox.AppendText("Sistema: $($os.Caption)`r`n")
    $outputBox.AppendText("CPU: $($cpu.Name)`r`n")
})
$form.Controls.Add($btnInfo)

$btnOptimizar = New-Object System.Windows.Forms.Button
$btnOptimizar.Location = New-Object System.Drawing.Point(20, 120)
$btnOptimizar.Size = New-Object System.Drawing.Size(200, 35)
$btnOptimizar.Text = "Optimizar Sistema"
$btnOptimizar.BackColor = [System.Drawing.Color]::LightCoral
$btnOptimizar.Add_Click({
    $outputBox.AppendText("Optimizando sistema...`r`n")
    [System.GC]::Collect()
    $outputBox.AppendText("Memoria liberada`r`n")
})
$form.Controls.Add($btnOptimizar)

$btnLimpiarOutput = New-Object System.Windows.Forms.Button
$btnLimpiarOutput.Location = New-Object System.Drawing.Point(270, 120)
$btnLimpiarOutput.Size = New-Object System.Drawing.Size(200, 35)
$btnLimpiarOutput.Text = "Limpiar Salida"
$btnLimpiarOutput.BackColor = [System.Drawing.Color]::LightGray
$btnLimpiarOutput.Add_Click({
    $outputBox.Clear()
})
$form.Controls.Add($btnLimpiarOutput)

$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(20, 170)
$labelStatus.Size = New-Object System.Drawing.Size(450, 20)
$labelStatus.Text = "Salida de comandos:"
$labelStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelStatus)

$btnCerrar = New-Object System.Windows.Forms.Button
$btnCerrar.Location = New-Object System.Drawing.Point(370, 330)
$btnCerrar.Size = New-Object System.Drawing.Size(100, 30)
$btnCerrar.Text = "Cerrar"
$btnCerrar.BackColor = [System.Drawing.Color]::Red
$btnCerrar.ForeColor = [System.Drawing.Color]::White
$btnCerrar.Add_Click({
    $form.Close()
})
$form.Controls.Add($btnCerrar)

$outputBox.AppendText("Bienvenido al Optimizador de PC`r`n")
$outputBox.AppendText("Selecciona una opcion`r`n")

Write-Host "Mostrando interfaz grafica..." -ForegroundColor Green
$form.ShowDialog() | Out-Null

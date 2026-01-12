# ============================================
# Historico-Optimizaciones.ps1
# Sistema de historial de optimizaciones con JSON
# ============================================

$ErrorActionPreference = 'SilentlyContinue'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath

. "$scriptPath\Logger.ps1"
Initialize-Logger

$historialPath = "$scriptPath\historico-optimizaciones.json"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Función para agregar entrada al historial
function Add-OptimizacionHistorial {
    param(
        [string]$Script,
        [string]$Descripcion,
        [hashtable]$MetricasAntes,
        [hashtable]$MetricasDespues,
        [string]$Resultado
    )
    
    $entrada = @{
        Fecha = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Script = $Script
        Descripcion = $Descripcion
        MetricasAntes = $MetricasAntes
        MetricasDespues = $MetricasDespues
        Resultado = $Resultado
        Usuario = $env:USERNAME
        Equipo = $env:COMPUTERNAME
    }
    
    $historial = @()
    
    if (Test-Path $historialPath) {
        try {
            $historial = Get-Content $historialPath -Raw | ConvertFrom-Json
        } catch {
            Write-Log "Error al leer historial existente" -Level "WARNING"
        }
    }
    
    $historial += $entrada
    
    try {
        $historial | ConvertTo-Json -Depth 10 | Out-File -FilePath $historialPath -Encoding UTF8
        Write-Log "Entrada agregada al historial: $Script" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Error al guardar historial: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Función para ver historial
function Show-Historial {
    param([int]$Ultimas = 10)
    
    if (-not (Test-Path $historialPath)) {
        Write-Host "  ℹ️  No hay historial disponible aún" -ForegroundColor Gray
        return
    }
    
    try {
        $historial = Get-Content $historialPath -Raw | ConvertFrom-Json
        
        if ($historial.Count -eq 0) {
            Write-Host "  ℹ️  El historial está vacío" -ForegroundColor Gray
            return
        }
        
        $entradas = $historial | Select-Object -Last $Ultimas
        
        Write-Host "📊 ÚLTIMAS $Ultimas OPTIMIZACIONES" -ForegroundColor Cyan
        Write-Host ""
        
        $count = 1
        foreach ($entrada in $entradas) {
            Write-Host "[$count] $(Get-Date $entrada.Fecha -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Yellow
            Write-Host "    Script: $($entrada.Script)" -ForegroundColor White
            Write-Host "    Descripción: $($entrada.Descripcion)" -ForegroundColor Gray
            
            if ($entrada.MetricasAntes -and $entrada.MetricasDespues) {
                Write-Host "    Métricas:" -ForegroundColor Cyan
                
                if ($entrada.MetricasAntes.CPUPorcentaje) {
                    $cpuDelta = $entrada.MetricasDespues.CPUPorcentaje - $entrada.MetricasAntes.CPUPorcentaje
                    $color = if ($cpuDelta -lt 0) { "Green" } else { "Red" }
                    Write-Host "      CPU: $($entrada.MetricasAntes.CPUPorcentaje)% → $($entrada.MetricasDespues.CPUPorcentaje)% ($(if($cpuDelta -gt 0){'+'}else{''})$cpuDelta%)" -ForegroundColor $color
                }
                
                if ($entrada.MetricasAntes.RAMPorcentaje) {
                    $ramDelta = $entrada.MetricasDespues.RAMPorcentaje - $entrada.MetricasAntes.RAMPorcentaje
                    $color = if ($ramDelta -lt 0) { "Green" } else { "Red" }
                    Write-Host "      RAM: $($entrada.MetricasAntes.RAMPorcentaje)% → $($entrada.MetricasDespues.RAMPorcentaje)% ($(if($ramDelta -gt 0){'+'}else{''})$ramDelta%)" -ForegroundColor $color
                }
                
                if ($entrada.MetricasAntes.DiscoLibreGB) {
                    $discoDelta = $entrada.MetricasDespues.DiscoLibreGB - $entrada.MetricasAntes.DiscoLibreGB
                    $color = if ($discoDelta -gt 0) { "Green" } else { "Red" }
                    Write-Host "      Disco Libre: $($entrada.MetricasAntes.DiscoLibreGB) GB → $($entrada.MetricasDespues.DiscoLibreGB) GB ($(if($discoDelta -gt 0){'+'}else{''})$([math]::Round($discoDelta, 2)) GB)" -ForegroundColor $color
                }
            }
            
            $resultadoColor = switch ($entrada.Resultado) {
                "EXITOSO" { "Green" }
                "PARCIAL" { "Yellow" }
                "ERROR" { "Red" }
                default { "White" }
            }
            Write-Host "    Resultado: $($entrada.Resultado)" -ForegroundColor $resultadoColor
            Write-Host ""
            
            $count++
        }
        
    } catch {
        Write-Host "  ❌ Error al leer historial: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error al mostrar historial: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Función para estadísticas
function Show-Estadisticas {
    if (-not (Test-Path $historialPath)) {
        Write-Host "  ℹ️  No hay datos para estadísticas" -ForegroundColor Gray
        return
    }
    
    try {
        $historial = Get-Content $historialPath -Raw | ConvertFrom-Json
        
        if ($historial.Count -eq 0) {
            Write-Host "  ℹ️  No hay datos suficientes" -ForegroundColor Gray
            return
        }
        
        Write-Host "📈 ESTADÍSTICAS GLOBALES" -ForegroundColor Cyan
        Write-Host ""
        
        # Total de optimizaciones
        Write-Host "  Total de optimizaciones: $($historial.Count)" -ForegroundColor White
        
        # Por script
        $porScript = $historial | Group-Object -Property Script | Sort-Object Count -Descending
        Write-Host ""
        Write-Host "  Optimizaciones por script:" -ForegroundColor Yellow
        foreach ($grupo in $porScript) {
            Write-Host "    • $($grupo.Name): $($grupo.Count) veces" -ForegroundColor Gray
        }
        
        # Resultados
        $exitosos = ($historial | Where-Object { $_.Resultado -eq "EXITOSO" }).Count
        $parciales = ($historial | Where-Object { $_.Resultado -eq "PARCIAL" }).Count
        $errores = ($historial | Where-Object { $_.Resultado -eq "ERROR" }).Count
        
        Write-Host ""
        Write-Host "  Resultados:" -ForegroundColor Yellow
        Write-Host "    ✅ Exitosos: $exitosos" -ForegroundColor Green
        if ($parciales -gt 0) {
            Write-Host "    ⚠️  Parciales: $parciales" -ForegroundColor Yellow
        }
        if ($errores -gt 0) {
            Write-Host "    ❌ Errores: $errores" -ForegroundColor Red
        }
        
        # Espacio liberado total
        $espacioTotal = 0
        foreach ($entrada in $historial) {
            if ($entrada.MetricasAntes.DiscoLibreGB -and $entrada.MetricasDespues.DiscoLibreGB) {
                $espacioTotal += ($entrada.MetricasDespues.DiscoLibreGB - $entrada.MetricasAntes.DiscoLibreGB)
            }
        }
        
        if ($espacioTotal -gt 0) {
            Write-Host ""
            Write-Host "  💾 Espacio liberado total: $([math]::Round($espacioTotal, 2)) GB" -ForegroundColor Cyan
        }
        
        # Primera y última optimización
        $primera = $historial[0].Fecha
        $ultima = $historial[-1].Fecha
        
        Write-Host ""
        Write-Host "  Primera optimización: $primera" -ForegroundColor Gray
        Write-Host "  Última optimización: $ultima" -ForegroundColor Gray
        
    } catch {
        Write-Host "  ❌ Error al calcular estadísticas: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Función para exportar historial
function Export-Historial {
    if (-not (Test-Path $historialPath)) {
        Write-Host "  ℹ️  No hay historial para exportar" -ForegroundColor Gray
        return
    }
    
    $exportPath = "$scriptPath\Historial-Exportado-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    try {
        $historial = Get-Content $historialPath -Raw | ConvertFrom-Json
        
        $reporte = @()
        $reporte += "=========================================="
        $reporte += "HISTORIAL DE OPTIMIZACIONES"
        $reporte += "Exportado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $reporte += "=========================================="
        $reporte += ""
        
        foreach ($entrada in $historial) {
            $reporte += "FECHA: $($entrada.Fecha)"
            $reporte += "SCRIPT: $($entrada.Script)"
            $reporte += "DESCRIPCIÓN: $($entrada.Descripcion)"
            $reporte += "EQUIPO: $($entrada.Equipo)"
            $reporte += "USUARIO: $($entrada.Usuario)"
            
            if ($entrada.MetricasAntes) {
                $reporte += ""
                $reporte += "MÉTRICAS ANTES:"
                if ($entrada.MetricasAntes.CPUPorcentaje) {
                    $reporte += "  CPU: $($entrada.MetricasAntes.CPUPorcentaje)%"
                }
                if ($entrada.MetricasAntes.RAMPorcentaje) {
                    $reporte += "  RAM: $($entrada.MetricasAntes.RAMPorcentaje)%"
                }
                if ($entrada.MetricasAntes.DiscoLibreGB) {
                    $reporte += "  Disco Libre: $($entrada.MetricasAntes.DiscoLibreGB) GB"
                }
            }
            
            if ($entrada.MetricasDespues) {
                $reporte += ""
                $reporte += "MÉTRICAS DESPUÉS:"
                if ($entrada.MetricasDespues.CPUPorcentaje) {
                    $reporte += "  CPU: $($entrada.MetricasDespues.CPUPorcentaje)%"
                }
                if ($entrada.MetricasDespues.RAMPorcentaje) {
                    $reporte += "  RAM: $($entrada.MetricasDespues.RAMPorcentaje)%"
                }
                if ($entrada.MetricasDespues.DiscoLibreGB) {
                    $reporte += "  Disco Libre: $($entrada.MetricasDespues.DiscoLibreGB) GB"
                }
            }
            
            $reporte += ""
            $reporte += "RESULTADO: $($entrada.Resultado)"
            $reporte += "-" * 50
            $reporte += ""
        }
        
        $reporte | Out-File -FilePath $exportPath -Encoding UTF8
        
        Write-Host "  ✅ Historial exportado: $exportPath" -ForegroundColor Green
        Write-Log "Historial exportado a: $exportPath" -Level "SUCCESS"
        
    } catch {
        Write-Host "  ❌ Error al exportar: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Función para limpiar historial antiguo
function Clear-HistorialAntiguo {
    param([int]$DiasAntiguedad = 90)
    
    if (-not (Test-Path $historialPath)) {
        Write-Host "  ℹ️  No hay historial para limpiar" -ForegroundColor Gray
        return
    }
    
    try {
        $historial = Get-Content $historialPath -Raw | ConvertFrom-Json
        $fechaLimite = (Get-Date).AddDays(-$DiasAntiguedad)
        
        $historialFiltrado = $historial | Where-Object {
            (Get-Date $_.Fecha) -gt $fechaLimite
        }
        
        $eliminados = $historial.Count - $historialFiltrado.Count
        
        if ($eliminados -gt 0) {
            $historialFiltrado | ConvertTo-Json -Depth 10 | Out-File -FilePath $historialPath -Encoding UTF8
            Write-Host "  ✅ Eliminadas $eliminados entradas antiguas (>$DiasAntiguedad días)" -ForegroundColor Green
            Write-Log "Historial limpiado: $eliminados entradas eliminadas" -Level "SUCCESS"
        } else {
            Write-Host "  ℹ️  No hay entradas antiguas para eliminar" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  ❌ Error al limpiar historial: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# MENÚ PRINCIPAL
do {
    Write-Host "OPCIONES:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Ver historial (últimas 10)" -ForegroundColor Green
    Write-Host "  [2] Ver historial completo (últimas 50)" -ForegroundColor Green
    Write-Host "  [3] Ver estadísticas" -ForegroundColor Cyan
    Write-Host "  [4] Exportar historial a TXT" -ForegroundColor Yellow
    Write-Host "  [5] Limpiar entradas antiguas (>90 días)" -ForegroundColor Red
    Write-Host "  [6] Registrar optimización manual" -ForegroundColor Magenta
    Write-Host "  [0] Salir" -ForegroundColor Gray
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opción"
    Write-Host ""
    
    switch ($opcion) {
        '1' {
            Show-Historial -Ultimas 10
            Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
            Read-Host
            Clear-Host
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }
        '2' {
            Show-Historial -Ultimas 50
            Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
            Read-Host
            Clear-Host
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }
        '3' {
            Show-Estadisticas
            Write-Host ""
            Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
            Read-Host
            Clear-Host
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }
        '4' {
            Export-Historial
            Write-Host ""
            Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
            Read-Host
            Clear-Host
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }
        '5' {
            Write-Host "⚠️  ¿Estás seguro de eliminar entradas antiguas?" -ForegroundColor Yellow
            $confirmar = Read-Host "Escribe 'SI' para confirmar"
            if ($confirmar -eq 'SI') {
                Clear-HistorialAntiguo -DiasAntiguedad 90
            } else {
                Write-Host "  Operación cancelada" -ForegroundColor Gray
            }
            Write-Host ""
            Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
            Read-Host
            Clear-Host
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }
        '6' {
            Write-Host "REGISTRAR OPTIMIZACIÓN MANUAL" -ForegroundColor Cyan
            Write-Host ""
            
            $script = Read-Host "Nombre del script/herramienta"
            $descripcion = Read-Host "Descripción"
            
            $resultado = ""
            do {
                $resultado = Read-Host "Resultado (EXITOSO/PARCIAL/ERROR)"
            } while ($resultado -notin @("EXITOSO", "PARCIAL", "ERROR"))
            
            $success = Add-OptimizacionHistorial -Script $script -Descripcion $descripcion -MetricasAntes @{} -MetricasDespues @{} -Resultado $resultado
            
            if ($success) {
                Write-Host ""
                Write-Host "  ✅ Optimización registrada correctamente" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "  ❌ Error al registrar optimización" -ForegroundColor Red
            }
            
            Write-Host ""
            Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
            Read-Host
            Clear-Host
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "HISTORIAL DE OPTIMIZACIONES" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }
        '0' {
            Write-Host "Saliendo..." -ForegroundColor Gray
            Write-Log "Módulo de historial cerrado" -Level "INFO"
        }
        default {
            Write-Host "  ⚠️  Opción no válida" -ForegroundColor Yellow
            Write-Host ""
        }
    }
    
} while ($opcion -ne '0')

Write-Host ""

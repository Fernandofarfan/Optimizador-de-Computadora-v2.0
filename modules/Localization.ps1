$ErrorActionPreference = "Continue"

$configPath = "$PSScriptRoot\config.json"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "      CONFIGURACION DE IDIOMA / LANGUAGE SETTINGS" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1] Espanol (Spanish)" -ForegroundColor Green
Write-Host "[2] English" -ForegroundColor Green
Write-Host "[3] Portugues (Portuguese)" -ForegroundColor Green
Write-Host "[0] Cancelar / Cancel" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona idioma / Select language"

switch ($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Idioma seleccionado: ESPANOL" -ForegroundColor Green
        Write-Host ""
        
        # Guardar configuracion
        if (Test-Path $configPath) {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $config | Add-Member -NotePropertyName "language" -NotePropertyValue "es" -Force
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
            Write-Host "[OK] Idioma guardado en configuracion" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "El optimizador esta configurado en espanol." -ForegroundColor Cyan
        Write-Host "Todos los menus y mensajes se mostraran en espanol." -ForegroundColor Gray
    }
    "2" {
        Write-Host ""
        Write-Host "Selected language: ENGLISH" -ForegroundColor Green
        Write-Host ""
        
        # Guardar configuracion
        if (Test-Path $configPath) {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $config | Add-Member -NotePropertyName "language" -NotePropertyValue "en" -Force
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
            Write-Host "[OK] Language saved in configuration" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "The optimizer is now configured in English." -ForegroundColor Cyan
        Write-Host "Note: Main menu will remain in Spanish as translations are not fully implemented." -ForegroundColor Yellow
        Write-Host "This is a demonstration of the language preference system." -ForegroundColor Gray
    }
    "3" {
        Write-Host ""
        Write-Host "Idioma selecionado: PORTUGUES" -ForegroundColor Green
        Write-Host ""
        
        # Guardar configuracion
        if (Test-Path $configPath) {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $config | Add-Member -NotePropertyName "language" -NotePropertyValue "pt" -Force
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
            Write-Host "[OK] Idioma salvo na configuracao" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "O otimizador esta configurado em portugues." -ForegroundColor Cyan
        Write-Host "Nota: Menu principal permanecera em espanhol pois as traducoes nao estao totalmente implementadas." -ForegroundColor Yellow
        Write-Host "Esta e uma demonstracao do sistema de preferencia de idioma." -ForegroundColor Gray
    }
    "0" {
        Write-Host ""
        Write-Host "Operacion cancelada / Operation cancelled" -ForegroundColor Gray
    }
    default {
        Write-Host ""
        Write-Host "Opcion invalida / Invalid option" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Presiona ENTER para continuar / Press ENTER to continue"

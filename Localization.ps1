$ErrorActionPreference = "Continue"
Write-Host "CONFIGURACION DE IDIOMA / LANGUAGE SETTINGS" -ForegroundColor Green
Write-Host ""
Write-Host "[1] Espanol (Spanish)" -ForegroundColor Cyan
Write-Host "[2] English" -ForegroundColor Cyan
Write-Host "[3] Portugues (Portuguese)" -ForegroundColor Cyan
Write-Host "[0] Cancelar / Cancel" -ForegroundColor Yellow
Write-Host ""
$opcion = Read-Host "Selecciona idioma / Select language"

switch ($opcion) {
    "1" {
        Write-Host ""
        Write-Host "Idioma seleccionado: ESPANOL" -ForegroundColor Green
        Write-Host ""
        Write-Host "Nota: El optimizador ya esta configurado en espanol por defecto." -ForegroundColor Yellow
        Write-Host "Esta funcionalidad guardaria la preferencia para futuras ejecuciones." -ForegroundColor Gray
    }
    "2" {
        Write-Host ""
        Write-Host "Selected language: ENGLISH" -ForegroundColor Green
        Write-Host ""
        Write-Host "Note: This would configure the optimizer to display messages in English." -ForegroundColor Yellow
        Write-Host "This functionality would save the preference for future executions." -ForegroundColor Gray
    }
    "3" {
        Write-Host ""
        Write-Host "Idioma selecionado: PORTUGUES" -ForegroundColor Green
        Write-Host ""
        Write-Host "Nota: Isto configuraria o otimizador para exibir mensagens em portugues." -ForegroundColor Yellow
        Write-Host "Esta funcionalidade salvaria a preferencia para execucoes futuras." -ForegroundColor Gray
    }
    "0" {
        Write-Host "Operacion cancelada / Operation cancelled" -ForegroundColor Gray
    }
    default {
        Write-Host "Opcion invalida / Invalid option" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Presiona ENTER para continuar / Press ENTER to continue"

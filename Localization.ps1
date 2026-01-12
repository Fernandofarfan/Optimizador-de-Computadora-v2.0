<#
.SYNOPSIS
    Sistema de internacionalización (i18n) para Optimizador de PC
.DESCRIPTION
    Soporte multi-idioma: Español, English, Português, Français
.VERSION
    4.0.0
#>

$Global:CurrentLanguage = "es"
$Global:AvailableLanguages = @("es", "en", "pt", "fr")

$Global:Translations = @{
    es = @{
        Welcome = "Bienvenido al Optimizador de PC v4.0.0"
        SelectOption = "Seleccione una opción"
        Processing = "Procesando..."
        Completed = "Completado"
        Error = "Error"
        Success = "Éxito"
        Cancel = "Cancelar"
        Continue = "Continuar"
        Exit = "Salir"
        
        # Menu items
        Menu_Analysis = "Análisis del Sistema"
        Menu_Optimization = "Optimización"
        Menu_Cleaning = "Limpieza"
        Menu_Tools = "Herramientas"
        Menu_Settings = "Configuración"
        Menu_About = "Acerca de"
        
        # System info
        System_CPU = "CPU"
        System_RAM = "RAM"
        System_Disk = "Disco"
        System_OS = "Sistema Operativo"
        System_Version = "Versión"
        
        # Actions
        Action_Analyze = "Analizar"
        Action_Optimize = "Optimizar"
        Action_Clean = "Limpiar"
        Action_Backup = "Respaldar"
        Action_Restore = "Restaurar"
        Action_Update = "Actualizar"
        
        # Messages
        Msg_StartingAnalysis = "Iniciando análisis del sistema..."
        Msg_AnalysisComplete = "Análisis completado exitosamente"
        Msg_OptimizationStart = "Iniciando optimización..."
        Msg_OptimizationComplete = "Optimización completada"
        Msg_ErrorOccurred = "Se produjo un error: {0}"
        Msg_RequiresAdmin = "Esta operación requiere permisos de administrador"
        Msg_CreateRestorePoint = "¿Desea crear un punto de restauración?"
        Msg_BackupComplete = "Respaldo completado exitosamente"
        
        # Features
        Feature_GamingMode = "Modo Gaming"
        Feature_AutoUpdate = "Auto-actualización"
        Feature_Logging = "Registro avanzado"
        Feature_Notifications = "Notificaciones"
        Feature_Reports = "Reportes HTML"
        Feature_Testing = "Framework de testing"
    }
    
    en = @{
        Welcome = "Welcome to PC Optimizer v4.0.0"
        SelectOption = "Select an option"
        Processing = "Processing..."
        Completed = "Completed"
        Error = "Error"
        Success = "Success"
        Cancel = "Cancel"
        Continue = "Continue"
        Exit = "Exit"
        
        # Menu items
        Menu_Analysis = "System Analysis"
        Menu_Optimization = "Optimization"
        Menu_Cleaning = "Cleaning"
        Menu_Tools = "Tools"
        Menu_Settings = "Settings"
        Menu_About = "About"
        
        # System info
        System_CPU = "CPU"
        System_RAM = "RAM"
        System_Disk = "Disk"
        System_OS = "Operating System"
        System_Version = "Version"
        
        # Actions
        Action_Analyze = "Analyze"
        Action_Optimize = "Optimize"
        Action_Clean = "Clean"
        Action_Backup = "Backup"
        Action_Restore = "Restore"
        Action_Update = "Update"
        
        # Messages
        Msg_StartingAnalysis = "Starting system analysis..."
        Msg_AnalysisComplete = "Analysis completed successfully"
        Msg_OptimizationStart = "Starting optimization..."
        Msg_OptimizationComplete = "Optimization completed"
        Msg_ErrorOccurred = "An error occurred: {0}"
        Msg_RequiresAdmin = "This operation requires administrator privileges"
        Msg_CreateRestorePoint = "Do you want to create a restore point?"
        Msg_BackupComplete = "Backup completed successfully"
        
        # Features
        Feature_GamingMode = "Gaming Mode"
        Feature_AutoUpdate = "Auto-update"
        Feature_Logging = "Advanced logging"
        Feature_Notifications = "Notifications"
        Feature_Reports = "HTML Reports"
        Feature_Testing = "Testing framework"
    }
    
    pt = @{
        Welcome = "Bem-vindo ao Otimizador de PC v4.0.0"
        SelectOption = "Selecione uma opção"
        Processing = "Processando..."
        Completed = "Concluído"
        Error = "Erro"
        Success = "Sucesso"
        Cancel = "Cancelar"
        Continue = "Continuar"
        Exit = "Sair"
        
        # Menu items
        Menu_Analysis = "Análise do Sistema"
        Menu_Optimization = "Otimização"
        Menu_Cleaning = "Limpeza"
        Menu_Tools = "Ferramentas"
        Menu_Settings = "Configurações"
        Menu_About = "Sobre"
        
        # System info
        System_CPU = "CPU"
        System_RAM = "RAM"
        System_Disk = "Disco"
        System_OS = "Sistema Operacional"
        System_Version = "Versão"
        
        # Actions
        Action_Analyze = "Analisar"
        Action_Optimize = "Otimizar"
        Action_Clean = "Limpar"
        Action_Backup = "Backup"
        Action_Restore = "Restaurar"
        Action_Update = "Atualizar"
        
        # Messages
        Msg_StartingAnalysis = "Iniciando análise do sistema..."
        Msg_AnalysisComplete = "Análise concluída com sucesso"
        Msg_OptimizationStart = "Iniciando otimização..."
        Msg_OptimizationComplete = "Otimização concluída"
        Msg_ErrorOccurred = "Ocorreu um erro: {0}"
        Msg_RequiresAdmin = "Esta operação requer privilégios de administrador"
        Msg_CreateRestorePoint = "Deseja criar um ponto de restauração?"
        Msg_BackupComplete = "Backup concluído com sucesso"
        
        # Features
        Feature_GamingMode = "Modo Gaming"
        Feature_AutoUpdate = "Atualização automática"
        Feature_Logging = "Registro avançado"
        Feature_Notifications = "Notificações"
        Feature_Reports = "Relatórios HTML"
        Feature_Testing = "Framework de testes"
    }
    
    fr = @{
        Welcome = "Bienvenue dans PC Optimizer v4.0.0"
        SelectOption = "Sélectionnez une option"
        Processing = "Traitement en cours..."
        Completed = "Terminé"
        Error = "Erreur"
        Success = "Succès"
        Cancel = "Annuler"
        Continue = "Continuer"
        Exit = "Quitter"
        
        # Menu items
        Menu_Analysis = "Analyse du Système"
        Menu_Optimization = "Optimisation"
        Menu_Cleaning = "Nettoyage"
        Menu_Tools = "Outils"
        Menu_Settings = "Paramètres"
        Menu_About = "À propos"
        
        # System info
        System_CPU = "CPU"
        System_RAM = "RAM"
        System_Disk = "Disque"
        System_OS = "Système d'exploitation"
        System_Version = "Version"
        
        # Actions
        Action_Analyze = "Analyser"
        Action_Optimize = "Optimiser"
        Action_Clean = "Nettoyer"
        Action_Backup = "Sauvegarder"
        Action_Restore = "Restaurer"
        Action_Update = "Mettre à jour"
        
        # Messages
        Msg_StartingAnalysis = "Début de l'analyse du système..."
        Msg_AnalysisComplete = "Analyse terminée avec succès"
        Msg_OptimizationStart = "Début de l'optimisation..."
        Msg_OptimizationComplete = "Optimisation terminée"
        Msg_ErrorOccurred = "Une erreur s'est produite: {0}"
        Msg_RequiresAdmin = "Cette opération nécessite des privilèges d'administrateur"
        Msg_CreateRestorePoint = "Voulez-vous créer un point de restauration?"
        Msg_BackupComplete = "Sauvegarde terminée avec succès"
        
        # Features
        Feature_GamingMode = "Mode Gaming"
        Feature_AutoUpdate = "Mise à jour automatique"
        Feature_Logging = "Journalisation avancée"
        Feature_Notifications = "Notifications"
        Feature_Reports = "Rapports HTML"
        Feature_Testing = "Framework de test"
    }
}

function Get-Translation {
    <#
    .SYNOPSIS
        Obtiene una traducción para la clave especificada
    .PARAMETER Key
        Clave de traducción
    .PARAMETER Language
        Idioma (opcional, usa el idioma actual por defecto)
    .PARAMETER Arguments
        Argumentos para formatear la cadena
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [string]$Language = $Global:CurrentLanguage,
        
        [Parameter(Mandatory = $false)]
        [object[]]$Arguments
    )
    
    if (-not $Global:Translations.ContainsKey($Language)) {
        $Language = "en"
    }
    
    $translation = $Global:Translations[$Language]
    
    if ($translation.ContainsKey($Key)) {
        $text = $translation[$Key]
        
        if ($Arguments) {
            return ($text -f $Arguments)
        }
        
        return $text
    }
    
    return $Key
}

function Set-Language {
    <#
    .SYNOPSIS
        Establece el idioma actual
    .PARAMETER Language
        Código de idioma (es, en, pt, fr)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("es", "en", "pt", "fr")]
        [string]$Language
    )
    
    $Global:CurrentLanguage = $Language
    Write-Host "✓ $(Get-Translation 'Success'): Language set to $Language" -ForegroundColor Green
}

function Get-CurrentLanguage {
    <#
    .SYNOPSIS
        Obtiene el idioma actual
    #>
    return $Global:CurrentLanguage
}

function Get-AvailableLanguages {
    <#
    .SYNOPSIS
        Obtiene lista de idiomas disponibles
    #>
    return $Global:AvailableLanguages
}

function Show-LanguageMenu {
    <#
    .SYNOPSIS
        Muestra menú de selección de idioma
    #>
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "LANGUAGE SELECTION / SELECCIÓN DE IDIOMA" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "1. Español" -ForegroundColor White
    Write-Host "2. English" -ForegroundColor White
    Write-Host "3. Português" -ForegroundColor White
    Write-Host "4. Français" -ForegroundColor White
    
    $selection = Read-Host "`nSelect / Seleccione (1-4)"
    
    switch ($selection) {
        "1" { Set-Language -Language "es" }
        "2" { Set-Language -Language "en" }
        "3" { Set-Language -Language "pt" }
        "4" { Set-Language -Language "fr" }
        default { 
            Write-Host "Invalid selection / Selección inválida" -ForegroundColor Red
            Set-Language -Language "es"
        }
    }
}

# Auto-detectar idioma del sistema
function Initialize-Language {
    <#
    .SYNOPSIS
        Inicializa el idioma basado en la configuración del sistema
    #>
    $systemLang = (Get-Culture).TwoLetterISOLanguageName
    
    if ($Global:AvailableLanguages -contains $systemLang) {
        $Global:CurrentLanguage = $systemLang
    } else {
        # Default to Spanish
        $Global:CurrentLanguage = "es"
    }
    
    Write-Verbose "Language initialized: $Global:CurrentLanguage"
}

# Alias para facilitar uso
New-Alias -Name "t" -Value Get-Translation -Force -ErrorAction SilentlyContinue
New-Alias -Name "Get-T" -Value Get-Translation -Force -ErrorAction SilentlyContinue

# Exportar funciones
Export-ModuleMember -Function Get-Translation, Set-Language, Get-CurrentLanguage, Get-AvailableLanguages, Show-LanguageMenu, Initialize-Language
Export-ModuleMember -Alias t, Get-T

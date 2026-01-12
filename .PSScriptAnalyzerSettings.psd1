@{
    # Configuración para PSScriptAnalyzer - v4.0.0
    IncludeRules = @(
        'PSAlignAssignmentStatement',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidGlobalAliases',
        'PSAvoidGlobalVariables',
        'PSAvoidInvokeExpression',
        'PSAvoidNullCoalescingOperator',
        'PSAvoidPositionalBooleanParameters',
        'PSAvoidPositionalParameters',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidUsingBareWriteHost',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingWMICmdlet',
        'PSMissingModuleManifestField',
        'PSPossibleIncorrectComparisonWithNull',
        'PSPossibleIncorrectUsageOfComparisonOperator',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseCmdletCorrectly',
        'PSUseConsistentIndentation',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseLiteralInitializerForHashtable',
        'PSUseNamedParameters',
        'PSUseOutputTypeCorrectly',
        'PSUsePSCredentialType',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseUTF8EncodingForHelpFile'
    )
    
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPositionalParameters',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseConsistentWhitespace'
    )
    
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize = 4
        }
        
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }
        
        PSUseSingularNouns = @{
            Enable = $true
            NounAllowList = @()
        }
    }
}


@{
    # Configuración para PSScriptAnalyzer
    IncludeRules = @(
        'PSAlignAssignmentStatement',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidGlobalAliases',
        'PSAvoidGlobalFunctions',
        'PSAvoidGlobalVariables',
        'PSAvoidInvokeExpression',
        'PSAvoidNullCoalescingOperator',
        'PSAvoidParameterAliases',
        'PSAvoidPositionalBooleanParameters',
        'PSAvoidPositionalParameters',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidUsingBareWriteHost',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingOldCmsletAliases',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingUserNameAndPassWordParams',
        'PSAvoidUsingWMICmdlet',
        'PSBaselineAssignmentRulesInPlace',
        'PSMissingModuleManifestField',
        'PSPlaceCloseBrace',
        'PSPlaceOpenBrace',
        'PSPossibleIncorrectComparisonWithNull',
        'PSPossibleIncorrectUsageOfComparisonOperator',
        'PSPossibleIncorrectUsageOfRedirectionOperator',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSReturnCorrectTypesForDynamicParameters',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseCompatibleCmdlets',
        'PSUseCompatibleCommands',
        'PSUseCompatibleSyntax',
        'PSUseCompatibleTypes',
        'PSUseCmdletCorrectly',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseLiteralInitializerForHashtable',
        'PSUseNamedParameters',
        'PSUseOutputTypeCorrectly',
        'PSUsePSCredentialType',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseToExportFieldsInManifest',
        'PSUseUTF8EncodingForHelpFile'
    )
    
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPositionalParameters'
    )
    
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $false
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $false
            IgnoreOneLineBlock = $true
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize = 4
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeOperatorPlacement = 'AfterPreviousLine'
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

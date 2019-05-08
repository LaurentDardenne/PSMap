
  Set-Location G:\PS\PSMap
  ipmo G:\PS\PSMap\src\Dependency\Dependency.psm1 -force
  $path= 'G:\PS\PSMap\Test\SourceCode\CommandsDependencies.ps1'

  Function Read-Dependency {
       param(
           [string] $Path
       )
    
       try {
        $EAP=$ErrorActionPreference
        $ErrorActionPreference='Stop'
        if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage')
        { Throw "The Powershell language mode must be 'FullLanguage'"}
       }catch {
         $ErrorActionPreference=$EAP
         Return
       }


     $CurrentContener=New-Contener -Path (Convert-Path $Path) -Type Script
     [Environment]::CurrentDirectory = $CurrentContener.FileInfo.DirectoryName
     $Ast=Get-Ast -FilePath $Path
    #  if ( (Get-Variable $ErrorsList).Value.Count -gt 0  )
    #  {
    #     $Er= New-Object System.Management.Automation.ErrorRecord(
    #             (New-Object System.ArgumentException("The code contains syntax errors.")), 
    #             "InvalidSyntax", 
    #             "InvalidData",
    #             "[AST]"
    #            )  
  
    #     $PSCmdlet.WriteError($Er)
    #  }
    # } catch [System.ArgumentException] {
    #   if ($_.FullyQualifiedErrorId -eq 'InvalidSyntax,Get-AST')
    #   { Write-debug "$ErrorsAst"}
    # }
    $Commands=$ast.FindAll({ param($Ast) $Ast -is [System.Management.Automation.Language.CommandAst] },$true)
    #TODO     &$function:bob  $function:bob.InvokeXXX()
    
    $FunctionWithAssign=$ast.FindAll(
        { param($Ast) 
        ($Ast -is [System.Management.Automation.Language.AssignmentStatementAst]) -and
        ($Ast.Left.VariablePath.DriveName -eq 'function') -and 
        ($Ast.Right.Expression.StaticType.fullname -eq 'System.Management.Automation.ScriptBlock')
        },$true)
    #$s.Left.VariablePath.UserPath -replace '^function:',''    

    #Return Microsoft.PowerShell.Commands.ModuleSpecification
    $Ast.ScriptRequirements.RequiredModules

    foreach ($UsingStatement in $Ast.UsingStatements)
    { Get-UsingStatementParameter $UsingStatement $global:ErrorsAst }

    foreach ($Command in $Commands)
    {
        $CommandName=$Command.GetCommandName()
        if ($null -ne $CommandName)
        {
            if ($CommandName -match 'Import-Module|IPMO')
            { Get-InformationModule $Command -Contener $CurrentContener; Continue }
        
            if ($CommandName -match 'Start-Process|saps|start')
            { Get-InformationProgram $Command ; Continue }
        
            try {
              $FileName=ConvertTo-FileInfo $CommandName
               #note : pour get-commande si une clause Using provoque une erreur alors sa propriété Scriptblock -eq $null
              if ($Filename.Extension -eq '.ps1')
              { Get-InformationScript $Command $FileName ; Continue }
              else
              { Write-Warning "todo Programm ? '$CommandName'" }
            } catch {
              Write-Warning "Is not a file name '$CommandName'"
            }

            if ($CommandName -match 'Add-Type')
            { Get-InformationDLL $Command ; Continue }
        }
        if ($Command.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst])
        {
            $CmdInfo=Get-Command $Command.CommandElements[0].Value
            # System.Management.Automation.AliasInfo
            # System.Management.Automation.ApplicationInfo
            # System.Management.Automation.CmdletInfo
            # System.Management.Automation.ExternalScriptInfo
            # System.Management.Automation.FunctionInfo
            # System.Management.Automation.RemoteCommandInfo #Call Get-Command on a remote server
            # System.Management.Automation.ScriptInfo
            if ($CmdInfo -is [System.Management.Automation.ApplicationInfo])
            {
            $CmdInfo|
                Select-Object Name,Source,@{ Name='ArgumentList';e={$Command.CommandElements[0].Parent.toString() -replace $Command.CommandElements[0].Value,''} }
            Continue 
            }
        }
        Write-Error "Foreach Commands: unknown case: '$($Command)'"; Continue
    }

    $Expressions=$Ast.FindAll({ param($Ast) $Ast -is [System.Management.Automation.Language.InvokeMemberExpressionAst] },$true)
    foreach ($Current in $Expressions)
    {
        if ($Current.Expression.Typename -match '(^System\.Reflection\.Assembly$|Reflection\.Assembly$)')
        {
            if ($Current.Member -match '(^UnsafeLoadFrom$|^Load$|^LoadFile$ |^LoadFrom$|^LoadWithPartialNameS)')
            {
                #TODO Load peut avoir des signatures ayant en 1er param un type différent de string
                #LoadWithPartialName
                #la classe AssemblyName peut déterminer ces cas
                #todo si pas.dll alors c'est un nom court ('System.Windows.Forms')
                # ou un nom long 'System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5cS61934eO89'
                if ($Current.Arguments[0] -is [System.Management.Automation.Language.StringConstantExpressionAst])
                {
                    $Value=$Current.Arguments[0].value
                    if ($Value -notmatch '\.dll$')
                    {
                        try {
                            Write-warning "not a dll"
                            #The file name of the assembly is unknown here, it should be in the GAC
                            New-NamespaceDependency -Assembly $Value
                        }
                        catch
                        {
                            #todo error or flag into type ‘NamespaceDependency' ?
                            Write-Warning "DLL analyze impossible for : $Value"
                        }
                    }
                    else
                    {
                        New-DLLDependency $Current.Arguments[0].value
                        [pscustomObject]@{
                            PSTypeName='DLLDependency';
                            Name=$name
                        }
                    }
                }
                else
                {
                    #TODO
                    # unresolved (informations)
                    Write-warning "$($current.Arguments[0].GetType().FullName)"
                }
            }
        }
        else
        {
        Write-Error "Foreach Expressions : unknown case : '$($Current)'"; Continue
        }
    }
}

$InformationCommands=Read-Dependency $path

$InformationCommands|
  where-object {
    ($_ -is [PSCustomObject]) -and ($_.PsTypenames[0] -eq 'InformationScript')
  }

$InformationCommands|Group-Object -Property @{'expression'={$_.gettype().fullname}}|fl
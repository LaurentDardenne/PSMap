
$sbRead={
    Set-Location G:\PS\PSMap
    #todo doit étre sans erreur de syntaxe
    #différencier, dans la liste d'erreur, les intructions 'using' en échec sur des modules inexistant
    #try {
       #create $global:ErrorsAst list
     $Ast=Get-Ast -FilePath '.\Test\SourceCode\CommandsDependencies.ps1'
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
}

.$sbRead

#Return Microsoft.PowerShell.Commands.ModuleSpecification
$Ast.ScriptRequirements.RequiredModules

foreach ($UsingStatement in $Ast.UsingStatements)
{ Get-UsingStatementParameter $UsingStatement $global:ErrorsAst }

$InformationCommands=foreach ($Command in $Commands)
{
    $CommandName=$Command.GetCommandName()
    if ($null -ne $CommandName)
    {
        if ($CommandName -match 'Import-Module|IPMO')
        { Get-InformationModule $Command ; Continue }
      
        if ($CommandName -match 'Start-Process|saps|start')
        { Get-InformationProgram $Command ; Continue }
      
        try {
          $FileName=[System.IO.FileInfo]$CommandName
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
        $Command
        pause
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

 $InformationCommands|
  where-object {
      ($_ -is [PSCustomObject]) -and ($_.PsTypenames[0] -eq 'InformationScript')
  }
# Add-Type -AssemblyName System.ComponentModel.DataAnnotations
# [System.ComponentModel.DataAnnotations.KeyAttribute]
#todo 'identité composite',Unicité ?
#                             Module Name Or Module,Version,Guid
#                             ModulePath\V1\Name; ModulePath\V2\Name
#connaitre le parent
#info de définition de l'objet AST (powershell)
#info de relation de l'objet  (Graph)
#info de relative au type d'objet  (Rapport)
#Information de gestion (error, type d'appel)
#ex : pour une module $StaticParameters.Name la classe [Microsoft.PowerShell.Commands.ModuleSpecification]
#     ne contient -AsCustomObject  qui permet de déterminer si on visualise les fonction du module importés
#     Pour using le module peut ne pas exister, on ne peut donc avoir plus d'info sur l'objet
#     Idem pour une analyse  de DLL impossible 
#     Certain appel peuvent ne pas être résolu



Function Get-StaticParameterBinder{
 param(
    [System.Management.Automation.Language.CommandAst] $Command,
    [switch] $Module,
    [switch] $Process,
    [switch] $AddType
 ) 
  $binding =[System.Management.Automation.Language.StaticParameterBinder]::BindCommand($Command)
  if ($Module)
  {
     [pscustomobject]@{
        PSTypeName='ModuleStaticParameterBinder';
        PSMapKeys='Name'
        Ast=$Command
        Name = $binding.BoundParameters['Name'].ConstantValue
        FullyQualifiedName = $binding.BoundParameters['FullyQualifiedName'].Value
        AsCustomObject=$binding.BoundParameters['AsCustomObject'].ConstantValue
     }
  }
  elseif ($Process)
  {
     if ($null -ne $binding.BoundParameters['FilePath'].ConstantValue)
     { $Path=$binding.BoundParameters['FilePath'].ConstantValue }
     else
     { $Path=$binding.BoundParameters['FilePath'].Value }#Todo can contains variables
     [pscustomobject]@{
        PSTypeName='ProcessStaticParameterBinder';
        PSMapKeys='FilePath'
        Ast=$Command
        FilePath= $Path
        ArgumentList= $binding.BoundParameters['ArgumentList'].ConstantValue
     }
  }
  elseif ($AddType)
  {
     [pscustomobject]@{
        PSTypeName='AddTypeStaticParameterBinder'
        PSMapKeys='Path|LiteralPath|AssemblyName'
        Ast=$Command
        Path= $binding.BoundParameters['Path'].ConstantValue
        LiteralPath= $binding.BoundParameters['LiteralPath'].ConstantValue
         #from Gac
        AssemblyName= $binding.BoundParameters['AssemblyName'].ConstantValue
         #CodeDom dependencies
        ReferencedAssemblies= $binding.BoundParameters['ReferencedAssemblies'].ConstantValue
     }
  }
}

function Get-UsingStatementParameter{
#The referenced file must exist when the AST is build
#
#note: parsefile(ast) can return errors when a using statement define a unknown module
# The method VisitUsingStatement from the internal class SymbolResolve cal the method GetModulesFromUsingModule
# that call get-module to find the module informations

  Param (
    [System.Management.Automation.Language.UsingStatementAst] $UsingStatement,
    $AstParseStringError
  )
    Switch ($UsingStatement.UsingStatementKind)
    {
          # Assembly 0 A parse time reference to an assembly.
        'Assembly' { New-NamespaceDependency -Using $UsingStatement  }

          # Command 1 A parse time command alias.
        'Command' { Write-Error 'Not implemented in 5.1 or 6.2' }

          # Module 2 A parse time reference or alias to a module.
        'Module' {
                      #https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.usingstatementast.name
                      #Name 	: When Alias is null or ModuleSpecification is null, the item being used, otherwise the alias name.
                      if ( ($null -eq $UsingStatement.Alias) -or ($null -eq $UsingStatement.ModuleSpecification) )
                      { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($UsingStatement.Name) }
                      elseif ($null -ne $UsingStatement.ModuleSpecification) 
                      { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($UsingStatement.ModuleSpecification.KeyValuePairs) }
                      else {
                        write-warning "todo -> use assert ParserStrings.UsingStatementNotSupported);"
                      }
                 }

          # Namespace 3 A parse time statement that allows specifying types without their full namespace.
        'Namespace' { New-NamespaceDependency -Using $UsingStatement }

          # Type 4 A parse time type alias (type accelerator).
        'Type' { Write-Error 'Not implemented in 5.1 or 6.2' }
   }
}
function Get-InformationModule{
  param(
    [System.Management.Automation.Language.CommandAst] $Command
  )
    $CommandElement=$Command.CommandElements[1]
    $TypeName=$CommandElement.GetType().Name
    switch ($TypeName)
    {
        'ArrayLiteralAst'      {
                                    Foreach ($Name in $Commandelement.Elements.value)
                                    { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($Name) }
                               }

        'CommandParameterAst' {
                                    $StaticParameters=Get-StaticParameterBinder $Command -Module
                                    if ( $Null -ne $StaticParameters.Name)
                                    {
                                        #todo use case: Import-module c:\temp\modules\my.dll
                                        #todo use case: Import-module c:\temp\my.ps1 -verbose
                                        # COMMENTAIRES : Chargement du module à partir du chemin « C:\temp\fun.ps1 ».
                                        # COMMENTAIRES : Appel de source de type « dot sourcing » du fichier script « C:\temp\fun.ps1 ».
                                        [Microsoft.PowerShell.Commands.ModuleSpecification]::New($Parameters.Name)
                                    }
                                    if( $Null -ne $StaticParameters.FullyQualifiedName)
                                    {
                                       [Microsoft.PowerShell.Commands.ModuleSpecification]::New($StaticParameters.FullyQualifiedName.KeyValuePairs)
                                    }
                                }

        'HashtableAst'      {
                               [Microsoft.PowerShell.Commands.ModuleSpecification]::New($CommandElement.KeyValuePairs)
                            }

        'StringConstantExpressionAst' { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($CommandElement.Value) }
            
         default { Write-error "Get-InformationModule: the recognition of this type is not available: $($TypeName)"}
    }
}

function Get-InformationProgram{
   param(
     [System.Management.Automation.Language.CommandAst] $Command
   )
   Get-StaticParameterBinder $Command -Process
}
function Get-InformationScript{
  param(
     [System.Management.Automation.Language.CommandAst] $Command,
      [System.IO.FileInfo]$FileInfo
  )
 function New-InformationScript{
   param(
      $FileName,
      $InvocationOperator
   )
   return @{FileName=$FileName; InvocationOperator=$InvocationOperator}      
}

#$Command.CommandElement.Count -eq 0  without parameter
#$Command.CommandElement.Count -gt 0  with parameters
#New-InformationScript -Name $Command.CommandElements[0].Value -InvocationOperator $Command.InvocationOperator
New-InformationScript -FileName $FileInfo.FullName -InvocationOperator $Command.InvocationOperator
}

function Get-InformationDLL{
  param(
    [System.Management.Automation.Language.CommandAst] $Command
  )
  function New-InformationDLL{
    param(
      $Name
     )
   return @{Name=$Name}
  }
  $Parameters=Get-StaticParameterBinder $Command -AddType
}

function Get-AssemblyVersion{
  param (
    $Value
  )
   #Return the the contains of the attribut ;  [assembly: AssemblyVersion("1.0.0.0")]
 try {
   #First try to use a path
  $AssemblyInfo=[System.Reflection.Assembly]::ReflectionOnlyLoadFrom($Value)
  $AssemblyInfo.GetName().Version
 } catch {
    try {
      #Next, try to use full assembly name
      $AssemblyName=[System.Reflection.AssemblyName]$Value
      $AssemblyName.Version
    } catch {
      return $null
    }
 }
}

Function New-NamespaceDependency{
  [CmdletBinding(DefaultParameterSetName='Assembly')]
  param(
      [Parameter(ParameterSetName='Assembly', Position=0)]
     $Assembly,
     
      [Parameter(ParameterSetName='Using', Position=0)]
     $Using
  )
 if ($PSCmdlet.ParameterSetName -eq 'Using')
 {
    if ($Using.UsingStatementKind -eq 'Assembly')
    {
       $Name=$Using.Name.Value
       return [pscustomobject]@{
                 PSTypeName='NamespaceDependency'
                 PSMapKeys='Name'
                 Ast=$Using
                 Name= $Using.Name.Extent
                 #Version= (get-item $Name).Versioninfo.Fileversion
                 Version=Get-AssemblyVersion $Name
                 File= $Name
                 Type='UsingAssembly'
               }
    }
    if ($Using.UsingStatementKind -eq 'Namespace')
    {
       return [pscustomobject]@{
                 PSTypeName='NamespaceDependency'
                 Name= $Using.Name.Value
                 Version= $null
                 File= $Null
                 Type='UsingNameSpace'
             }
    }
 }
 else
 {
    $AssemblyName=[System.Reflection.AssemblyName]$Assembly
    [pscustomobject]@{
       PSTypeName='NamespaceDependency'
       Name= $AssemblyName.Name
       Version= $AssemblyName.Version
       File=$null
       Type='Reﬂection'
    }
 }
}

Function New-DLLDependency{
  param ($Name)

  [pscustomobject]@{
    PSTypeName='DLLDependency'
    Name=$name
  }
}

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

foreach ($Command in $Commands)
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

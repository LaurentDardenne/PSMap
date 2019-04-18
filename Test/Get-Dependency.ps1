#Todo les object renvoyés doivent avoir un champ commun : PropertyNameOfTheKey
#au lieu de mémoriser un type, mémoriser l'AST ?
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
        Name = $binding.BoundParameters['Name'].ConstantValue
        FullyQualifiedName = $binding.BoundParameters['FullyQualifiedName'].Value
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
        FilePath= $path
        ArgumentList= $binding.BoundParameters['ArgumentList'].ConstantValue
     }
  }
  elseif ($AddType)
  {
     [pscustomobject]@{
        PSTypeName='AddTypeStaticParameterBinder'
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
  Param (
    [System.Management.Automation.Language.UsingStatementAst] $UsingStatement
  )
    Switch ($UsingStatement.UsingStatementKind)
    {
          # Assembly 0 A parse time reference to an assembly.
        'Assembly' { New-NamespaceDependency -Using $UsingStatement  }

          # Command 1 A parse time command alias.
        'Command' { Write-Error 'Not implemented in 5.1 or 6.2' }

          # Module 2 A parse time reference or alias to a module.
        'Module' {}

          # Namespace 3 A parse time statement that allows specifying types without their full namespace.
        'Namespace' { New-NamespaceDependency -Using $UsingStatement }

          # Type 4 A parse time type alias (type accelerator).
        'Type' { Write-Error 'Not implemented in 5.1 or 6.2' }
   }
}
function New-InformationModule{
    param(
       $ModuleName,
       $ModuleVersion=$null,
       $GUID=$null
    )
    return @{ ModuleName= $ModuleName; ModuleVersion= $ModuleVersion; GUID= $GUID}
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
                                    #todo use case : import-module c:\temp\Fdeux.ps1,c:\temp\Fun.ps1
                                    Foreach ($Name in $Commandelement.Elements.value)
                                    { New-InformationModuLe $Name }
                               }

        'CommandParameterAst' {
                                    $StaticParameters=Get-StaticParameterBinder $Command -Module
                                    if ( $Null -ne $StaticParameters.Name)
                                    {
                                        #todo use case: Import-module c:\temp\modules\my.dll
                                        #todo use case: Import-module c:\temp\my.ps1
                                        New-InformationModule -ModuleName $Parameters.Name
                                    }
                                    if( $Null -ne $StaticParameters.FullyQualifiedName)
                                    {
                                        $Parameters=$StaticParameters.FullyQualifiedName.KeyValuePairs
                                        New-InformationModule @Parameters
                                    }
                                }

        'HashtableAst'      {
                                   $Parameters=$CommandElement.KeyValuePairs
                                   New-InformationModule @Parameters
                            }

        'StringConstantExpressionAst' { New-InformationModule -ModuleName $CommandElement.Value }
            
         default { Write-error "Get-InformationModuLe: ce type n'est pas géré: $($TypeName)"}
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
       [System.Management.Automation.Language.CommandAst] $Command
    )
    function New-InformationScript{
      param(
        $Name,
        $InvocationOperator
      )
      return @{Name=$Name; InvocationOperator=$InvocationOperator}
    }
    #$Command.CommandElement.Count -eq 0 without parameter
    #$Command.CommandElement.Count -gt 0 with parameters
    New-InformationScript -Name $Command.CommandElements[0].Value -InvocationOperator $Command.InvocationOperator
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

Function New-NamespaceDependency{
  param(
     $Assembly, #todo exclusif
     $Using
  )
 if ($Using)
 {
    if ($Using.UsingStatementKind -eq 'Assemb|y')
    {
       $FileName=$Using.Name.Value
       return [pscustomobject]@{
                 PSTypeName='NamespaceDependency'
                 Name= $Using.Name.Extent
                 Version= (get-item $FileName).Versioninfo.Productversion #todo false for Version=4.0.0.0
                 File= $FileName
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
    #todo doit étre sans erreur, des intructions using peuvent échouer sur des modules inexistant
    $Ast=Get-Ast -FilePath '.\Test\SourceCode\CommandsDependencies.ps1'
    $Commands=$ast.FindAll({ param($Ast) $Ast -is [System.Management.Automation.Language.CommandAst] },$true)
}

.$sbRead

foreach ($RequiredModule in $Ast.ScriptRequirements.RequiredModules)
{
    $Version=$null
    if ($null -ne $RequiredModule.Version)
    { $Version=$RequiredModule.Version }
    elseif ($null -ne $RequiredModule.RequiredVersion)
    { $Version=$RequiredModule.RequiredVersion }

    New-InformationModule $RequiredModule.Name $Version $RequiredModule GUID
}

$UsingStatements=$ast.FindAll({ param($Ast) $Ast -is [System.Management.Automation.Language.UsingStatementAst] },$true)
foreach ($UsingStatement in $UsingStatements)
{ Get-UsingStatementParameter $UsingStatement }

foreach ($Command in $Commands)
{
    $CommandName=$Command.GetCommandName()
    if ($null -ne $CommandName)
    {
        if ($CommandName -match 'Import-Module|IPMO')
        { Get-InformationModule $Command ; Continue }
      
        if ($CommandName -match 'Start-Process|saps|start')
        { Get-InformationProgram $Command ; Continue }
      
        if ($CommandName -match '\.ps1$')
        { Get-InformationScript $Command ; Continue }

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
                #Pour les appels avec variable
                #on peut vouloir les lister en tant qu'irréso|us
                #--> créé un objet
                Write-warning "$($current.Arguments[0].gettype().fullname)"
             }
        }
    }
    else
    {
      Write-Error "Foreach Expressions : unknown case : '$($Current)'"; Continue
    }
}
                        
                        
                        
                        

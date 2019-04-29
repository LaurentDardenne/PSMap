# Add-Type -AssemblyName System.ComponentModel.DataAnnotations
# [System.ComponentModel.DataAnnotations.KeyAttribute]
#todo 'identité composite',Unicité ?
#                             Module Name Or Module,Version,Guid
#                             ModulePath\V1\Name; ModulePath\V2\Name

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
                                    # import-module c:\temp\Fdeux.ps1,@{} ?
                                    Foreach ($Name in $Commandelement.Elements.value)
                                    { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($Name) }
                               }

        'CommandParameterAst' {
                                    $StaticParameters=Get-StaticParameterBinder $Command -Module
                                    if ( $Null -ne $StaticParameters.Name)
                                    {
                                        #todo use case: Import-module c:\temp\modules\my.dll
                                        #todo use case: Import-module c:\temp\my.ps1
                                        [Microsoft.PowerShell.Commands.ModuleSpecification]::New($Parameters.Name)
                                    }
                                    if( $Null -ne $StaticParameters.FullyQualifiedName)
                                    {
                                       [Microsoft.PowerShell.Commands.ModuleSpecification]::New($StaticParameters.FullyQualifiedName.KeyValuePairs
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
    #todo doit étre sans erreur, des intructions using peuvent échouer sur des modules inexistant
    $Ast=Get-Ast -FilePath '.\Test\SourceCode\CommandsDependencies.ps1'
    $Commands=$ast.FindAll({ param($Ast) $Ast -is [System.Management.Automation.Language.CommandAst] },$true)
}

.$sbRead

#Return Microsoft.PowerShell.Commands.ModuleSpecification
$Ast.ScriptRequirements.RequiredModules

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

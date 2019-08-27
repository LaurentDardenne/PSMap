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
#ex : pour un module $StaticParameters.Name la classe [Microsoft.PowerShell.Commands.ModuleSpecification]
#     ne contient -AsCustomObject qui permet de déterminer si on visualise les fonctions du module importés
#     Pour Using le module peut ne pas exister, on ne peut donc avoir plus d'info sur l'objet
#     Idem pour une analyse  de DLL impossible 
#     Certain appels peuvent ne pas être résolus

#recherche des fichiers :
# supposer que les chemins relatifs le sont par rapport au script principal peut ne pas fonctionner
# rechercher ces dépendances dans une liste des fichiers établie avant l'analyse
#on peut donc avoir des dépendances incomplètes, mais on peut savoir lequelles.

#DOC:
# Le contexte d'exécution  influence le résultat.
#   Par exemple sur Windows 10    :  gcm get-aduser -> erreur
#   mais sur un serveur configuré :   gcm get-aduser -> OK autoloading de module si RSAT installé.

$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\DependencyLog4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params

#todo doit pointer sur le contexte de l'appelant
$sbIsScriptDotSource={ ($_ -is [PSCustomObject]) -and ($_.PsTypenames[0] -eq 'InformationScript') }

#codemap filtrer les commandes du runtime 
$script:RuntimeModules=@(
 'Microsoft.PowerShell.Core',
 'Microsoft.PowerShell.Diagnostics',
 'Microsoft.PowerShell.Host',
 'Microsoft.PowerShell.Management',
 'Microsoft.PowerShell.Security',
 'Microsoft.PowerShell.Utility',
 'Microsoft.PowerShell.LocalAccounts', #Windows 10 ?
 'Microsoft.WSMan.Management',
 'ISE',#todo à tester
 'PSDesiredStateConfiguration', #PS v4
 'PSScheduledJob',
 'PSWorkflow',
 'PSWorkflowUtility'
)
<#
todo : ForEach-Object Where-Object 
 si on filtre sur le cmdlet du runtime on doit préciser au moins une fois lesquels sont utilisés
Cmdlet          Compare-Object                                     3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          ForEach-Object                                     3.0.0.0    Microsoft.PowerShell.Core
Cmdlet          Group-Object                                       3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          Measure-Object                                     3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          New-Object                                         3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          Select-Object                                      3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          Sort-Object                                        3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          Tee-Object                                         3.1.0.0    Microsoft.PowerShell.Utility
Cmdlet          Where-Object                                       3.0.0.0    Microsoft.PowerShell.Core

todo dependance : cf. Imbrication1.ps1

S'il existe + Import-Module avec des noms différents, le graph ne contient qu'une référence de Import-Moudle sans le nom de module
certaine commande définissant une dépendance (import-module, add-type) sont cité comlme commande dans le graph de fonctio net dans la liste des dépendances
il est présent dans les 2 cas mais n'a pas la même signification.

note : Test\SourceCode\Imbrication1.ps1
Si une fonction refédinie un même nom de fonction, les liens sont faux la dernière trouvée pointe sur le premier noeud ajouté, car le nom de vertex existe déjà.
cf digraph.
Utiliser un nom complet : s.f° ou m.f° ? Le nom du digraph est complet mais pas lors de sa visualisation
 Vertex.FullName= Test-Three.Test-One.Test-Two
 Vertex.Name= Test-Two
 
 Vertex.FullName=Test-Three2.Test-One.Test-Two 
 Vertex.Name=Test-Two 

#>

function Get-AST {
#from http://becomelotr.wordpress.com/2011/12/19/powershell-vnext-ast/
<#

.Synopsis
    Function to generate AST (Abstract Syntax Tree) for PowerShell code.
#>
  
  [CmdletBinding(DefaultParameterSetName = 'File')]
  param (
      # Path to file to process.
      [Parameter(Mandatory,ParameterSetName = 'File')]
      [Alias('Path','PSPath')]
      [ValidateScript({
          if (Test-Path -Path $_ -ErrorAction SilentlyContinue) {
              $true
          } else {
              throw "File does not exist!"
          }
      })]
      [string]$FilePath,
      
      # Input string to process.
      [Parameter(Mandatory,ParameterSetName = 'Input')]
      [Alias('Script','IS')]
      [string]$InputScript
  )

  $Tokens=$null
  $ErrorAst=$null

  switch ($psCmdlet.ParameterSetName) {
      File {
          $ParseFile = (Resolve-Path -Path $FilePath).ProviderPath
          $Ast= [System.Management.Automation.Language.Parser]::ParseFile(
              $ParseFile, 
              [ref]$Tokens,
              [ref]$ErrorAst
          )
      }
      Input {
          $Ast=[System.Management.Automation.Language.Parser]::ParseInput(
                $InputScript, 
                [ref]$Tokens,
                [ref]$ErrorAst
          )
      }
  }
  return  [pscustomobject]@{
            PSTypeName='AstParsing'
            Ast=$Ast
            Tokens=$Tokens
            ErrorAst=$ErrorAst
            FilePath=$FilePath
            InputScript=$InputScript
          }
}
  
function Test-ScriptName{
 param( [System.IO.FileInfo] $Path )
  $Path.Extension -eq '.ps1'
}

function ConvertTo-FileInfo{
  #todo voir les difficultés avec les différentes constructions de PSPath
  param ($Path)

  try
  { 
     #try to convert a relativ path with the current location
    $ScriptPath=Convert-Path $Path -ErrorAction 'Stop'
  } catch [System.Management.Automation.ItemNotFoundException] {
     $ScriptPath=$Path
  }
  [System.IO.FileInfo]$ScriptPath
}

Function New-Container{
  param(
      [Parameter(Mandatory=$True,position=0)]
    $Path,
      [Parameter(Mandatory=$True,position=1)]
      [ValidateSet('Script','Module','Scriptblock')]
    $Type
  )
  
  [pscustomobject]@{
    PSTypeName='Container';
    FileInfo=ConvertTo-FileInfo $Path;
    Type=$Type;
  }
}# New-Container


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

function ConvertTo-Hashtable {
  param($KeyValuePairs)
  
  $H=@{}
  $RegEx="^('|`")(.*)('|`")$"
  $KeyValuePairs|
   Foreach-Object {
     $Key=$_.Item1.ToString() 
      #Item2 contains an AST object, we must remove the string delimiters
     $Value= ($_.Item2.toString()) -Replace $RegEx,'$2'
     $H.Add($Key,$Value)
   }
   return ,$H
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
    Write-Debug "Get-UsingStatementParameter '$($UsingStatement.UsingStatementKind)'"
    Switch ($UsingStatement.UsingStatementKind)
    {
          # Assembly 0 A parse time reference to an assembly.
        'Assembly' { New-NamespaceDependency -Using $UsingStatement  }

          # Command 1 A parse time command alias.
        'Command' { Write-Error 'Not implemented in 5.1 or 6.2' }

          # Module 2 A parse time reference or alias to a module.
        'Module' {
                    if ($null -ne $UsingStatement.ModuleSpecification) 
                    { 
                       Write-Debug "`t ModuleSpecification '$($UsingStatement.ModuleSpecification.KeyValuePairs|out-string)'"
                       $HashTable=ConvertTo-Hashtable $UsingStatement.ModuleSpecification.KeyValuePairs
                       [Microsoft.PowerShell.Commands.ModuleSpecification]::New($HashTable) 
                    }
                    elseif ( ($null -eq $UsingStatement.Alias) -and ($null -ne $UsingStatement.Name) )
                    {
                       #https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.usingstatementast.name
                       #Name        : When Alias is null or ModuleSpecification is null, the item being used, otherwise the alias name.
                       Write-Debug "`t ModuleSpecification alias null '$($UsingStatement.Name)'"
                       [Microsoft.PowerShell.Commands.ModuleSpecification]::New($UsingStatement.Name) 
                    }
                    else 
                    { Write-Warning "This syntax of the 'using' statement is not supported." } # Alias
              }

          # Namespace 3 A parse time statement that allows specifying types without their full namespace.
        'Namespace' { New-NamespaceDependency -Using $UsingStatement }

          # Type 4 A parse time type alias (type accelerator).
        'Type' { Write-Error 'Not implemented in 5.1 or 6.2' }
    }
}
  
function Get-InformationModule{
  param(
    [System.Management.Automation.Language.CommandAst] $Command,
    $Container
  )
    $CommandElement=$Command.CommandElements[1]
    $TypeName=$CommandElement.GetType().Name
    Write-Debug "Get-InformationModule $typename : $CommandElement"
    switch ($TypeName)
    {
        'ArrayLiteralAst'      {
                                    #todo Import-module File.ps1, File2.ps1
                                    Foreach ($Name in $Commandelement.Elements.value)
                                    { 
                                       Write-Debug "`t ModuleSpecification '$Name'"
                                       [Microsoft.PowerShell.Commands.ModuleSpecification]::New($Name) 
                                    }
                                }

        'CommandParameterAst' {
                                    $StaticParameters=Get-StaticParameterBinder $Command -Module
                                    if ( $Null -ne $StaticParameters.Name)
                                    {
                                        #todo use case: Import-module c:\temp\modules\my.dll
                                        # si c'est un module binaire ok, si c'est une dll dotnet sans déclaration de cmdlet
                                        #alors c'est une 'erreur' d'utilisation de IPMO comme IPMO File.sp1 peut l'être (confusion)
                                        if  (Test-ScriptName $StaticParameters.Name)
                                        { 
                                              #Retrieve the current path
                                            $FileInfo=ConvertTo-FileInfo $StaticParameters.Name 
                                            #Import-module File.ps1 is equal to dotsource .ps1
                                            New-InformationScript -FileInfo $FileInfo -InvocationOperator 'Dot'
                                        }
                                        else 
                                        {  
                                           Write-Debug "`t ModuleSpecification '$($StaticParameters.Name)'"
                                           [Microsoft.PowerShell.Commands.ModuleSpecification]::New($StaticParameters.Name) 
                                        }
                                    }
                                    if( $Null -ne $StaticParameters.FullyQualifiedName)
                                    { 
                                       Write-Debug "`t ModuleSpecification '$($StaticParameters.FullyQualifiedName.KeyValuePairs|Out-String)'"
                                       $HashTable=ConvertTo-Hashtable $StaticParameters.FullyQualifiedName.KeyValuePairs
                                       [Microsoft.PowerShell.Commands.ModuleSpecification]::New($HashTable) 
                                    }
                              }                                        

        'HashtableAst'      {
                                Write-Debug "`t ModuleSpecification '$($CommandElement.KeyValuePairs|Out-String)'"
                                $HashTable=ConvertTo-Hashtable $CommandElement.KeyValuePairs
                                [Microsoft.PowerShell.Commands.ModuleSpecification]::New($HashTable) 
                            }

        'StringConstantExpressionAst' { 
                                        $FileInfo=ConvertTo-FileInfo $CommandElement.Value
                                        if  (Test-ScriptName $FileInfo)
                                        { 
                                            #Import-module File.ps1 is equal to dotsource .ps1
                                            New-InformationScript -FileInfo $FileInfo -InvocationOperator 'Dot'
                                        }
                                        else
                                        { 
                                          Write-Debug "`t ModuleSpecification '$($CommandElement.value)'"
                                          [Microsoft.PowerShell.Commands.ModuleSpecification]::New($CommandElement.Value) 
                                        }
                                      }        

          default { Write-error "Get-InformationModule: the recognition of this type is not available: $($TypeName)"}
    }
}

function Get-InformationProgram{
   param(
     [System.Management.Automation.Language.CommandAst] $Command
   )
   Get-StaticParameterBinder $Command -Process
}
function New-InformationScript{
  param(
    [System.IO.FileInfo] $FileInfo,
    [string] $InvocationOperator
  )
  return [pscustomobject]@{
            PSTypeName='InformationScript';
            FileInfo=$FileInfo;
            #By default 
            # this statement : .\One.ps1
            # is equal to &'.\One.ps1'                 
            # 'Unknown' -eq 'Ampersand'
            InvocationOperator=$InvocationOperator
          }
}
function Get-InformationScript{
  param(
     [System.Management.Automation.Language.CommandAst] $Command,
     [System.IO.FileInfo]$FileInfo
  )

  #$Command.CommandElement.Count -eq 0  without parameter
  #$Command.CommandElement.Count -gt 0  with parameters
  #New-InformationScript -Name $Command.CommandElements[0].Value -InvocationOperator $Command.InvocationOperator
  New-InformationScript -FileInfo $FileInfo -InvocationOperator $Command.InvocationOperator
}

function Get-InformationDLL{
  param(
    [System.Management.Automation.Language.CommandAst] $Command
  )
 
 Get-StaticParameterBinder $Command -AddType
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
       Type='Reflection'
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

function ConvertTo-AssemblyDependency {
  param ($Expression)

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
              { New-DLLDependency $Current.Arguments[0].value }
          }
          else
          {
              #TODO
              # unresolved (informations) Quoi, où, raison ?
              # dépendance trouvée mais fichier introuvable.
              Write-warning "$($current.Arguments[0].GetType().FullName)"
          }
      }
  }
  else
  {
    #todo add log not an error
    Write-Error "Foreach Expressions : unknown case : '$($Current)'"
    Continue 
  }
}

function ConvertTo-CommandDependency {
  param (
     $Command,
     $Container
  )

  $CommandName=$Command.GetCommandName()
  # todo peut renvoyer une string contenant 'ModuleName\Cmd' -> Microsoft.PowerShell.Utility\Get-Member
  # une fonction peut avoir ce nom : function Microsoft.PowerShell.Utility\Get-Member{}
  if ($null -ne $CommandName)
  {
      if ($CommandName -match 'Update-FormatData|Update-TypeData')
      { Write-Warning "todo ETS" }# Get-InformationETS $Command -Container $Container; Continue }  #todo

      elseif ($CommandName -match 'Import-Module|IPMO')
      { Get-InformationModule $Command -Container $Container; Continue } 
  
      elseif ($CommandName -match 'start|Start-Process|saps') #todo on peut avoir un apple via splatting 'Start @params'
      { Get-InformationProgram $Command ; Continue }
  
      try {
        $FileInfo=ConvertTo-FileInfo $CommandName
          #note : pour get-commande (SMA.ExternalScriptInfo) si une clause Using provoque une erreur alors sa propriété Scriptblock -eq $null
        if (Test-ScriptName $FileInfo)
        { Get-InformationScript $Command $FileInfo ; Continue }
        else
        { Write-Debug "This command is not taken into consideration '$CommandName'" }
      } catch {
        Write-Error "Exception during converting a file name '$CommandName' : $_"
      }

      if ($CommandName -match 'Add-Type')
      { Get-InformationDLL $Command ; Continue }
  }

  #Pour "if (Microsoft.PowerShell.Utility\Get-Member -InputObject $requiredModuleObject -Name 'ModuleName')"
  #Microsoft.PowerShell.Utility\Get-Member est le détail d'une entrée de type CommandAst
  if ($Command.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst])
  {
      try {
        $CmdInfo=Get-Command $Command.CommandElements[0].Value -ErrorAction Stop
        #TODO  System.Management.Automation.AliasInfo
        # System.Management.Automation.FunctionInfo -> digraph
        if ($CmdInfo -is [System.Management.Automation.ApplicationInfo])
        {
          $CmdInfo|
          Select-Object Name,Source,@{ Name='ArgumentList';e={$Command.CommandElements[0].Parent.toString() -replace $Command.CommandElements[0].Value,''} }
          Continue 
        }
        #todo System.Management.Automation.CmdletInfo association avec son conteneur
      } catch [System.Management.Automation.CommandNotFoundException] {
      Write-Debug "$_ "
      }
  }
  #todo add log not a warning
  Write-Warning "Foreach Commands: unknown case: '$($Command)'"; Continue
}

#Les dépendances constitue un graphe et pas un arbre.
#todo On doit éviter de reparser un fichier déjà parsé 
Function Read-Dependency {
   [CmdletBinding(DefaultParameterSetName = "Path")]
    param(
        [ValidateNotNullOrEmpty()] 
        [Parameter(Position=0, Mandatory=$true,ParameterSetName="Path")]
      [string] $Path,

        [ValidateNotNullOrEmpty()] 
        [Parameter(Position=0, Mandatory=$true,ParameterSetName="CodeMap")]
      $Container,

        [ValidateNotNullOrEmpty()] 
        [Parameter(Position=1, Mandatory=$true,ParameterSetName="CodeMap")]
      $Ast
    )

  try {
   $EAP=$ErrorActionPreference
   $ErrorActionPreference='Stop'
   if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage')
   { Throw "The Powershell language mode must be 'FullLanguage'"}
  } catch {
     Return
  } finally {
     $ErrorActionPreference=$EAP
  }
  
  if ($PsCmdlet.ParameterSetName -eq "Path")
  {  
    $Container=New-Container -Path (Convert-Path $Path) -Type Script
    $AstParsing=Get-Ast -FilePath $Path
    $Ast=$AstParsing.Ast
  }
   # todo backup location ?
  [Environment]::CurrentDirectory = $Container.FileInfo.DirectoryName

   #TODO add Visitor to speed up the analysis. Extend Digraph class ?

  $Commands=$Ast.FindAll({ 
     param($Ast) 
     $Result=$Ast -is [System.Management.Automation.Language.CommandAst]
     Write-Debug "is CommandAst ? : $Result $($AST)"
     $Result},$true)

  #TODO     &$function:bob  $function:bob.InvokeXXX()
  $FunctionWithAssign=$ast.FindAll( { param($Ast) 
    $Result=($Ast -is [System.Management.Automation.Language.AssignmentStatementAst]) -and
    ($Ast.Left.VariablePath.DriveName -eq 'function') -and 
    ($Ast.Right.Expression.StaticType.fullname -eq 'System.Management.Automation.ScriptBlock')
    Write-Debug "is Function with Assignment ? : $Result $($AST)"
    $Result},$true)
   #$s.Left.VariablePath.UserPath -replace '^function:',''    

  #Return Microsoft.PowerShell.Commands.ModuleSpecification
  $RequiredModules=$Ast.ScriptRequirements.RequiredModules
  if ($null -ne $RequiredModules)
  { $RequiredModules }

  foreach ($UsingStatement in $Ast.UsingStatements)
  { Get-UsingStatementParameter $UsingStatement $global:ErrorsAst }

  foreach ($Command in $Commands)
  {  ConvertTo-CommandDependency -Command $Command -Container $Container}

#TODO
  #Contenu
  # [System.Management.Automation.Language.ScriptBlockAst] 

  #Appel
  # [System.Management.Automation.Language.ScriptBlockExpressionAst]

  #Affectation
  # [System.Management.Automation.Language.AssignmentStatementAst]  $var= [System.Management.Automation.Language.CommandExpressionAst] 

  $Expressions=$Ast.FindAll({ 
    param($Ast) 
    $Result=$Ast -is [System.Management.Automation.Language.InvokeMemberExpressionAst] 
    Write-Debug "is InvokeMemberExpressionAst ? : $Result $($AST)"
    $Result },$true)
  
    foreach ($Current in $Expressions)
    { ConvertTo-AssemblyDependency -Expression $Current }
}

function ConvertTo-DependencyObjectMap{
  param(
      [ValidateNotNullOrEmpty()] 
      [Parameter(Position=0, Mandatory=$true)]
    $CodeMap
  )

  Switch ($_.pstypenames[0])
  {
     'Assembly' { }

     'Microsoft.PowerShell.Commands.ModuleSpecification' { }

     'InformationScript' { }

     'NamespaceDependency' { }

     'DLLDependency' { }
# todo
# 'ModuleStaticParameterBinder';
# 'ProcessStaticParameterBinder';
# 'AddTypeStaticParameterBinder'
# ps1mxl
     Default { throw 'Not implementerd'}
 }
}

function Group-Dependency{
  param ($Dependencies)
  $Dependencies|
   Group-Object @{e={$_.pstypenames[0]}}
}

function Format-Dependency{
  param ($Dependencies)
  $Dependencies|
   Group-Object @{e={$_.pstypenames[0]}}|
   Format-List -GroupBy Name
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName 
}#OnRemovePsIonicZip

# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }
#Export-ModuleMember -Function * -Variable 

#Export-ModuleMember Get-Ast Internal

#todo Read-Dependency doit-elle émettre des conteneurs ou des objets PS/AST ?
#retrouver la liste des cmdlets d'une dll : (get-assemblies).ExportedTypes|? {$_.IsSubclassOf([System.Management.Automation.PSCmdlet])}
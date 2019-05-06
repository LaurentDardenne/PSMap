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

#todo doit pointer sur le contexte de l'appelant
$sbIsScriptDotSource={ ($_ -is [PSCustomObject]) -and ($_.PsTypenames[0] -eq 'InformationScript') }

function Test-ScriptName{
 param( [System.IO.FileInfo] $Path )
  $Path.Extension -eq '.ps1'
}

function ConvertTo-FileInfo{
  #todo voir les difficultés avec les différentes constructions de PSPath
  param ($Path)

  $ScriptPath=Convert-Path $Path
  [System.IO.FileInfo]$ScriptPath
}

Function New-Contener{
  param(
           [Parameter(Mandatory=$True,position=0)]
          $Path,
           [Parameter(Mandatory=$True,position=1)]
          $Type
  )
  
    [pscustomobject]@{
      PSTypeName='Contener';
      Path=$Path;
      Type=$Type;
     }
}# New-Contener

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
                   if ($null -ne $UsingStatement.ModuleSpecification) 
                   { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($UsingStatement.ModuleSpecification.KeyValuePairs) }
                   elseif ( ($null -eq $UsingStatement.Alias) -and ($null -ne $UsingStatement.Name) )
                   {
                      #https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.usingstatementast.name
                      #Name 	: When Alias is null or ModuleSpecification is null, the item being used, otherwise the alias name.
                     [Microsoft.PowerShell.Commands.ModuleSpecification]::New($UsingStatement.Name) 
                   }
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
                                    #todo on peut avoir Import-module File.ps1, File2.ps1 :/
                                    Foreach ($Name in $Commandelement.Elements.value)
                                    { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($Name) }
                               }

        'CommandParameterAst' {
                                    $StaticParameters=Get-StaticParameterBinder $Command -Module
                                    if ( $Null -ne $StaticParameters.Name)
                                    {
                                        #todo use case: Import-module c:\temp\modules\my.dll
                                        # si c'est un module binaire ok, si c'est une dll dotnet sans déclaration de cmdlet
                                        #alors c'est une 'erreur' d'utilisation de IPMO comme IPMO File.sp1 peut l'être (confusion)
                                        $FileInfo=ConvertTo-FileInfo $StaticParameters.Name
                                        if  (Test-ScriptName $FileInfo)
                                        { 
                                            #Import-module File.ps1 is equal to dotsource .ps1
                                            New-InformationScript -FileInfo $FileInfo -InvocationOperator 'Dot'
                                        }
                                        else 
                                        {   [Microsoft.PowerShell.Commands.ModuleSpecification]::New($StaticParameters.Name) }
                                    }
                                    if( $Null -ne $StaticParameters.FullyQualifiedName)
                                    { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($StaticParameters.FullyQualifiedName.KeyValuePairs) }
                              }                                        

        'HashtableAst'      {
                               [Microsoft.PowerShell.Commands.ModuleSpecification]::New($CommandElement.KeyValuePairs)
                            }

        'StringConstantExpressionAst' { 
                                        $FileInfo=ConvertTo-FileInfo $CommandElement.Value
                                        if  (Test-ScriptName $FileInfo)
                                        { 
                                           #Import-module File.ps1 is equal to dotsource .ps1
                                           New-InformationScript -FileInfo $FileInfo -InvocationOperator 'Dot'
                                        }
                                        else
                                        { [Microsoft.PowerShell.Commands.ModuleSpecification]::New($CommandElement.Value) }
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
  #todo must be managed by the caller
  # if ($InvocationOperator -eq 'Unknown')
  # {
  #     #By default 
  #     # this statement : .\One.ps1
  #     # is equal to &'.\One.ps1'      
  #     $InvocationOperator='Ampersand'
  # }
  return [pscustomobject]@{
            PSTypeName='InformationScript';
            FileInfo=$FileInfo;
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
  New-InformationScript -FileInfo $FileInfo.FullName -InvocationOperator $Command.InvocationOperator
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

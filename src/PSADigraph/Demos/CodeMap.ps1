#todoSuppose Language mode: FullLanguage
Import-Module PSAutograph
Add-type -Path ..\PSADigraph\bin\Debug\PSADigraph.dll



function Get-AST {
  #from http://becomelotr.wordpress.com/2011/12/19/powershell-vnext-ast/
  
  <#
  
  .Synopsis
     Function to generate AST (Abstract Syntax Tree) for PowerShell code.
  
  .DESCRIPTION
     This function will generate Abstract Syntax Tree for PowerShell code, either from file or direct input.
     Abstract Syntax Tree is a new feature of PowerShell 3 that should make parsing PS code easier.
     Because of nature of resulting object(s) it may be hard to read (different object types are mixed in output).
  
  .EXAMPLE
     $AST = Get-AST -FilePath MyScript.ps1
     $AST will contain syntax tree for MyScript script. Default are used for list of tokens ($Tokens) and errors ($Errors).
  
  .EXAMPLE
     Get-AST -Input 'function Foo { param ($Foo) Write-Host $Foo }' -Tokens MyTokens -Errors MyErors | Format-Custom
     Display function's AST in Custom View. $MyTokens contain all tokens, $MyErrors would be empty (no errors should be recorded).
  
  .INPUTS
     System.String
  
  .OUTPUTS
     System.Management.Automation.Languagage.Ast
  
  .NOTES
     Just concept of function to work with AST. Needs a polish and shouldn't polute Global scope in a way it does ATM.
  
  #>
  
  [CmdletBinding(
      DefaultParameterSetName = 'File'
  )]
  param (
      # Path to file to process.
      [Parameter(
          Mandatory,
          HelpMessage = 'Path to file to process',
          ParameterSetName = 'File'
      )]
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
      [Parameter(
          Mandatory,
          HelpMessage = 'String to process',
          ParameterSetName = 'Input'
  
      )]
      [Alias('Script','IS')]
      [string]$InputScript,
  
      # Name of the list of Errors.
      [Alias('EL')]
      [ValidateScript({$_ -ne 'ErrorsList'})] 
      [string]$ErrorsList = 'ErrorsAst',
      
      # Name of the list of Tokens.
      [Alias('TL')]
      [ValidateScript({$_ -ne 'TokensList'})]
      [string]$TokensList = 'Tokens',
      [switch] $Strict
  )
      New-Variable -Name $ErrorsList -Value $null -Scope Global -Force
      New-Variable -Name $TokensList -Value $null -Scope Global -Force

      switch ($psCmdlet.ParameterSetName) {
          File {
              $ParseFile = (Resolve-Path -Path $FilePath).ProviderPath
              [System.Management.Automation.Language.Parser]::ParseFile(
                  $ParseFile, 
                  [ref](Get-Variable -Name $TokensList),
                  [ref](Get-Variable -Name $ErrorsList)
              )
          }
          Input {
              [System.Management.Automation.Language.Parser]::ParseInput(
                  $InputScript, 
                  [ref](Get-Variable -Name $TokensList),
                  [ref](Get-Variable -Name $ErrorsList)
              )
          }
      }
     if ( (Get-Variable $ErrorsList).Value.Count -gt 0  )
     {
        $Er= New-Object System.Management.Automation.ErrorRecord(
                (New-Object System.ArgumentException("La syntaxe du code est erronée.")), 
                "InvalidSyntax", 
                "InvalidData",
                "[AST]"
               )  
  
        if ($Strict) 
        { $PSCmdlet.ThrowTerminatingError($Er)}
        else
        { $PSCmdlet.WriteError($Er)}
     }
} #Get-AST

Function New-CalledFunction{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
         [Parameter(position=1)]
        $CalledFunction=$null
    )

    Write-warning "CalledFunction $name -> $CalledFunction"
    [pscustomObject]@{
      PSTypeName='FunctionDependency';
      Name=$Name;
      CalledFunction=$CalledFunction
    }
}

Function New-FunctionDefinition{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
         [Parameter(position=1)]
         $FunctionDefined=$null
    )
  
    Write-warning "FunctionDefinition  $name -> $FunctionDefined"
    [pscustomObject]@{
      PSTypeName='FunctionDefinition';
      Name=$Name;
      FunctionDefined=$FunctionDefined
    }
}

Function New-FileDependency{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
         [Parameter(position=1)]
         $Usedfile=$null
    )
  
    Write-warning "FileDependency  $name -> $UsedFile"
    [pscustomObject]@{
      PSTypeName='Usedfile';
      Name=$Name;
      Usedfile=$Usedfile
    }
}

#Chaque nom de clé est un nom de type d'un objet à traiter, sa valeur est une hashtable possédant les clés suivantes :
# Follow_Property  : est un nom d'une propriété d'un objet, son contenu pouvant pointer sur un autre objet (de même type ou pas) ou être $null
# Follow_Label     : libellé de la relation (arête/edge) entre deux noeuds (sommet/vertex) du graphe
# Label_Property   : Nom de la propriété d'un objet contenant le libellé de chaque noeud (sommet) du graphe
$ObjectMap = @{
    "FunctionDependency" = @{
       Follow_Property = 'CalledFunction'
       Follow_Label = 'Call'
       Label_Property = 'Name'
    }
    "FunctionDefinition" = @{
      Follow_Property = 'FunctionDefined'
      Follow_Label = 'Define'
      Label_Property = 'Name'
    }
    "FileDependency" = @{
      Follow_Property = 'Usedfile'
      Follow_Label = 'Depend'
     Label_Property = 'Name'
   }
}

Function ConvertTo-Vertex {
 # return an array of PSADigraph.Vertex
    param (
      #AST Visitor
      [PSADigraph.FunctionReferenceDigraph] $funcDigraph,

      [Scriptblock] $Code
    ) 
  $Code.ast.Visit($funcDigraph)
  $funcDigraph.GetVertices() #Vertex=function name
}

function ConvertTo-ObjectMap {
  param (
      #AST Visitor
     [PSADigraph.FunctionReferenceDigraph] $funcDigraph,

     [Scriptblock] $Code,

     [Switch] $Function,

     [string[]] $Exclude=@()
  ) 
  $Vertices=ConvertTo-Vertex $funcDigraph $Code
  foreach ($vertex in $Vertices.GetEnumerator() )
  {  
    if ($Function -and ($Vertex.Ast -isnot [System.Management.Automation.Language.FunctionDefinitionAst]))
    { continue }

    $CurrentFunctionName=$Vertex.Name    
    if ($CurrentFunctionName -in $Exclude)
    { continue }

    Write-Debug "main $CurrentFunctionName type $($Vertex.ast.Gettype().fullname)" 
    $Parent=$Vertex.ast.parent.parent.parent 
    if ($Parent -is [System.Management.Automation.Language.FunctionDefinitionAst] )
    {
      Write-Debug "`t $($Parent.Name) define $CurrentFunctionName" 
      New-FunctionDefinition $Parent.Name -FunctionDefined @(New-FunctionDefinition -Name $CurrentFunctionName)
    }
    foreach ($CommandCalled in $funcDigraph.GetNeighbors($Vertex) )
    {
      if ($Function -and  ($CommandCalled.Ast -isnot [System.Management.Automation.Language.FunctionDefinitionAst]))
      { continue }
      
      if ($CommandCalled.Name -in $Exclude)
      { continue }

      Write-Debug "`tCall  $CommandCalled type $($CommandCalled.ast.Gettype().fullname)"
      New-CalledFunction -Name $CurrentFunctionName -CalledFunction @(New-CalledFunction -Name $CommandCalled.Name)
    }
  }  
}
function New-LookupTable {
  param( 
    [PSADigraph.FunctionReferenceDigraph] $funcDigraph,

    [PSADigraph.Vertex[]] $Vertices
 )
 Function Add-Name {
   param( $Name )
    if ($LookupTable.ContainsKey($Name))
    { $LookupTable.$Name++ }
    else
    { $LookupTable.Add($Name,0) }
  }       

 $LookupTable=@{}

 foreach ($Vertex in $Vertices) 
 {
   Add-Name $Vertex.Name
   foreach ($CommandCalled in $funcDigraph.GetNeighbors($Vertex) )
   { Add-Name $CommandCalled.Name }
  
 }
 return ,$LookupTable
}

$sb={
  Function Test-NestedThree {


    Function Test-NestedOne {
      Import-module c:\Module\test\test.psd1
    }
  
    Function Test-NestedTwo {
      Import-module c:\Module\test\test.psd1
    }
    
    #TODO
    #si NestedOne on retrouve le nom de commande mais pas si Test-NestedOne qui est une définition
    Test-NestedOne
    Test-NestedTwo
    notexist
    Import-module c:\Module\test\test.psd1
  }
}

$file=get-command 'MyFile.ps1' #todo
$funcDigraph = [PSADigraph.FunctionReferenceDigraph]::New()
$CodeMap=ConvertTo-ObjectMap  $funcDigraph $sb
#$CodeMap=ConvertTo-ObjectMap  $funcDigraph $File.Scriptblock -Exclude @('Evolution-Log') -Function

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $CodeMap -objectMap $ObjectMap
$resultModal=Show-MSaglGraph $viewer $g1

#Reference count ( Metrics ?) TODO
$vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
$Lookup=New-LookupTable $funcDigraph $Vertices
$Lookup.GetEnumerator()|Sort-Object value -Descending
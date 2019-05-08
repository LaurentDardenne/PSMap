Add-type -Path ..\PSADigraph\bin\Debug\PSADigraph.dll
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
  
        [System.Management.Automation.Language.ScriptBlockAst] $Ast
      ) 
    $Ast.Visit($funcDigraph)
    $funcDigraph.GetVertices() #Vertex=function name
}
  
function ConvertTo-FunctionObjectMap {
  param (
      #AST Visitor
      [PSADigraph.FunctionReferenceDigraph] $funcDigraph,

      [System.Management.Automation.Language.ScriptBlockAst] $Ast,

      [Switch] $Function,

      [string[]] $Exclude=@()
  ) 
  $Vertices=ConvertTo-Vertex $funcDigraph $Ast
 
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
  #Contains the occurrence number of a function
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

Function New-CodeMap{
  param(
        [Parameter(Mandatory=$True,position=0)]
      $Contener,
        [Parameter(Mandatory=$True,position=1)]
      $Ast,
        [Parameter(Mandatory=$True,position=2)]
      $DiGraph,
        [Parameter(Mandatory=$True,position=3)]
      $Dependencies
  )
  
  [pscustomobject]@{
    PSTypeName='CodeMap';
    Contener=$Contener;
    Ast=$Ast;
    DiGraph=$DiGraph;
    Dependencies=$Dependencies;
    }
}# New-CodeMap

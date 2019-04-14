Import-Module PSAutograph,PSMap
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
  
    Write-warning "FunctionDefinition  $name -> $CalledFunction"
    [pscustomObject]@{
      PSTypeName='FunctionDefinition';
      Name=$Name;
      FunctionDefined=$FunctionDefined
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

     [Scriptblock] $Code
  ) 
  $Vertices=ConvertTo-Vertex $funcDigraph $Code
  foreach ($vertex in $Vertices.GetEnumerator() )
  {  
    $CurrentFunctionName=$Vertex.Name
    Write-Debug "main $CurrentFunctionName type $($Vertex.ast.Gettype().fullname)" 
    $Parent=$Vertex.ast.parent.parent.parent 
    if ($Parent -is [System.Management.Automation.Language.FunctionDefinitionAst] )
    {
      Write-Debug "`t $($Parent.Name) define $CurrentFunctionName" 
      New-FunctionDefinition $Parent.Name -FunctionDefined @(New-FunctionDefinition -Name $CurrentFunctionName)
    }
    foreach ($CommandCalled in $funcDigraph.GetNeighbors($Vertex) )
    {
      Write-Debug "`tCall  $CommandCalled type $($CommandCalled.ast.Gettype().fullname)"
      New-CalledFunction -Name $CurrentFunctionName -CalledFunction @(New-CalledFunction -Name $CommandCalled.Name)
    }
  }  
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

$funcDigraph = [PSADigraph.FunctionReferenceDigraph]::New()
$CodeMap=ConvertTo-ObjectMap  $funcDigraph $sb

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $CodeMap -objectMap $ObjectMap
$resultModal=Show-MSaglGraph $viewer $g1
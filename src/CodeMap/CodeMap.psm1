#CodeMap.psm1

$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\CodeMapLog4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params


Function New-CalledFunction{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
        
        [Parameter(position=1)]
        $Container,

         [Parameter(position=2)]
        $CalledFunction=$null
    )

    Write-warning "CalledFunction $name -> $CalledFunction"
    [pscustomObject]@{
      PSTypeName='FunctionDependency';
      Name=$Name;
      Container=$Container;
      CalledFunction=$CalledFunction
    }
}
Function New-FunctionDefinition{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,

        [Parameter(position=1)]
        $Container,

        [Parameter(position=2)]
         $FunctionDefined=$null
    )
  
    Write-warning "FunctionDefinition  $name -> $FunctionDefined"
    [pscustomObject]@{
      PSTypeName='FunctionDefinition';
      Name=$Name;
      Container=$Container;
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
  #Renvoit 2 type d'objets:
  # une définition de fonction et les appels de fonction ( de commande + précisément) contenus dans cette définition.
  # Le propriétaire/conteneur est le script analysé.
  param (
      # To retrieve the Vertices list build by a PSADigraph.FunctionReferenceDigraph instance.
      $CodeMap,
       
      #Only consider function declarations, commands called unknown are not shown in the result.
      [Switch] $Function,

       #To exclude functions that generate noise in the display of the graph.
      [string[]] $Exclude=@()
  ) 

   #Here, one  vertex is a the function name
  $Vertices= $CodeMap.Digraph.GetVertices() 
  $Container=$CodeMap.Container
   
  foreach ($vertex in $Vertices )
  {  
    if ($Function -and ($Vertex.Ast -isnot [System.Management.Automation.Language.FunctionDefinitionAst]))
    { 
       Write-Debug "-Function Vertex ($($vertex.name)' is not a fonction $($Vertex.Ast.gettype())" 
       continue 
    }

    $CurrentFunctionName=$Vertex.Name    
    if ($CurrentFunctionName -in $Exclude)
    { continue }
    Write-Debug "main $CurrentFunctionName type $($Vertex.ast.Gettype().fullname)" 
    Write-Debug "`t has '$($CodeMap.Digraph.GetNeighbors($Vertex).count)' neighbors"
    $Parent=$Vertex.Ast.Parent.Parent.Parent
    Write-Debug "`t try to define `$Vertex.Ast.Parent.Parent.Parent" 
    if ($null -ne $Parent) 
    { 
      Write-Debug "`t 3 parent  $($Parent.Gettype().fullname)" 
      if ($Parent -is [System.Management.Automation.Language.FunctionDefinitionAst] )
      {
        Write-Debug "`t $($Parent.Name) define $CurrentFunctionName" 
        New-FunctionDefinition -Name $Parent.Name -Container $Container -FunctionDefined @(New-FunctionDefinition -Name $CurrentFunctionName)
      }
    }
    else 
    {
      Write-Debug "`t try to define `$Vertex.Ast.Parent.Parent" 
      $Parent=$Vertex.Ast.Parent.Parent
      if ($null -ne $Parent) 
      { 
        Write-Debug "`t 2 parent  $($Parent.Gettype().fullname)" 
        if ($Parent -is [System.Management.Automation.Language.ScriptBlockAst] )
        {
          Write-Debug "`t $($Parent.Name) define $CurrentFunctionName" 
          New-FunctionDefinition -Name $CurrentFunctionName -Container $Container 
        }
      }
      #continue
    }
    foreach ($CommandCalled in $CodeMap.Digraph.GetNeighbors($Vertex) )
    {
      Write-Debug "Neighbors $CommandCalled" 

      if ($Function -and  ($CommandCalled.Ast -isnot [System.Management.Automation.Language.FunctionDefinitionAst]))
      { continue }
      
      if ($CommandCalled.Name -in $Exclude)
      { continue }

      Write-Debug "`tCall  $CommandCalled type $($CommandCalled.Ast.Gettype().fullname)"
      New-CalledFunction -Name $CurrentFunctionName -Container $Container -CalledFunction @(New-CalledFunction -Name $CommandCalled.Name )
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
        $Container,
          [Parameter(Mandatory=$True,position=1)]
        $Ast,
          [Parameter(Mandatory=$True,position=2)]
        $DiGraph,
          [Parameter(position=3)]
        $Dependencies,
          [Parameter(position=4)]
        $ErrorAst
    )
    
     #search the functions to fill the digraph
    $Ast.Visit($Digraph)
  
    [pscustomobject]@{
      PSTypeName='CodeMap';
      Container=$Container;
      Ast=$Ast;
      DiGraph=$DiGraph;
      Dependencies=$Dependencies;
      ErrorAst=$ErrorAst
    }
}# New-CodeMap

function Format-FunctionGraph{
  param ($FunctionGraph)
  $FunctionGraph|
   Group-Object @{e={$_.pstypenames[0]}}|
   Format-List -GroupBy Name
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip

# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }
  
Export-ModuleMember -Function *
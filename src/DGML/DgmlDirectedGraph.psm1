# Module DgmlDirectedGraph.psm1

<#
Note
 DgmlUtils.ClrBoolean : contains true/false and True/False values
#>

Function New-DgmlGraph {
  #create a Dgml graph with a title and the Nodes and Links properties assigned
  # The Node list allow duplicate data without raising an exception
  # The Link list allow duplicate data without raising an exception

  param ([string] $Title)
  $Graph=[DgmlUtils.DirectedGraph]::new()
  #$Graph.Layout='DependencyMatrix'
  $Graph.Title=$Title
  
  $Graph.Nodes=New-DgmlNodeList 
  $Graph.Links=New-DgmlLinkList
  
  #$Graph.Layout='DependencyMatrix'

  Return $Graph
}

#todo add test to find duplicate node
# $Nodes.exists(predicate)

Function New-DgmlNodeList {
  Return New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphNode]  
}

Function New-DgmlNode {
  param([System.Collections.Hashtable]$Properties)
  
  Return ([DgmlUtils.DirectedGraphNode]$Properties)
}

$Links.Add([DgmlUtils.DirectedGraphLink]@{Source='a';Target='b'}) >$null

Function New-DgmlLinkList {
  Return New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphLink]  
}

Function New-DgmlLink {
  #create a link between two nodes.
  #New-DgmlLink @{Source='a';Target='b'}
  param([System.Collections.Hashtable]$Properties)

  Return ([DgmlUtils.DirectedGraphLink]$Properties)
}
function Get-DgmlEnums {
 #Retrieve the Enums list declared by [DgmlUtils.DirectedGraph
 #todo créer des raccourcis ?

  $Asm=[DgmlUtils.DirectedGraph].Assembly         
  $Asm.GetTypes()|
  Where-Object {$_.IsEnum}|
  ForEach-Object{
      Write-warning "$_"
      [System.enum]::GetValues($_)
  }
}
#Export-ModuleMember -Function * -Variable *
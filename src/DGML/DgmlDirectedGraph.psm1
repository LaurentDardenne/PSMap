
Function New-DgmlGraph {
  $Graph=[DgmlUtils.DirectedGraph]::new()
  #$Graph.Layout='DependencyMatrix'
  $Graph.Title="Test"
    #<Nodes>
  $Nodes=  New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphNode]  
}
function Get-DmglEnums {
 #Retrieve the Enums list declared by [DgmlUtils.DirectedGraph
 #todo créer des raccourcis ?

  $asm=[DgmlUtils.DirectedGraph].Assembly         
  $Asm.GetTypes()|
  Where-Object {$_.IsEnum}|
  ForEach-Object{
      Write-warning "$_"
      [System.enum]::GetValues($_)
  }
}
#Export-ModuleMember -Function * -Variable *
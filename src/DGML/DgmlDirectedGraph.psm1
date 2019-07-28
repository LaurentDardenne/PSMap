# Module DgmlDirectedGraph.psm1

<#
Note
 DgmlUtils.ClrBoolean : contains true/false and True/False values
#>

Function New-DgmlGraph {
  #create a Dgml graph with a title
  
  param ([string] $Title)
  $Graph=[DgmlUtils.DirectedGraph]::new()
  #$Graph.Layout='DependencyMatrix'
  $Graph.Title=$Title
  
  #$Graph.Layout='DependencyMatrix'

  Return $Graph
}

#todo add test to find duplicate node
# $Nodes.exists(predicate)

Function New-DgmlNodeList {
  # The Node list allow duplicate data without raising an exception
  Return ,(New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphNode])
}

Function New-DgmlLinkList {
  # The Link list allow duplicate data without raising an exception
  Return ,(New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphLink])
}

Function New-DgmlNode {
  param (
    [ValidateNotNull()]
    [System.Collections.Hashtable]$Properties
   )

  Return ([DgmlUtils.DirectedGraphNode]$Properties)
}

Function Add-DgmlNode {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory)]
      [AllowEmptyCollection()]
    [System.Collections.Generic.List[DgmlUtils.DirectedGraphNode]]$Nodes,

      [Parameter(Mandatory)]
      [ValidateNotNull()]
    [System.Collections.Hashtable]$Properties
   )

  $Node=[DgmlUtils.DirectedGraphNode]$Properties
  $Nodes.Add($Node) > $null
}

Function New-DgmlLink {
  #create a link between two nodes.  
    [CmdletBinding(DefaultParameterSetName = 'Hashtable')]
    param (
        [Parameter(Mandatory,ParameterSetName = 'Hashtable')]
      [System.Collections.Hashtable]$Properties,
      
        [Parameter(Mandatory,ParameterSetName = 'Property')]
      [String]$Source,
    
        [Parameter(Mandatory,ParameterSetName = 'Property')]
      [String]$Target
     )
   if ($PSCmdlet.ParameterSetName -eq 'Property')
   { $Properties =@{ Source=$Source;Target=$Target } }
  
   Return ([DgmlUtils.DirectedGraphLink]$Properties)
}
Function Add-DgmlLink {
  [CmdletBinding(DefaultParameterSetName = 'Hashtable')]
  param (
      [Parameter(Mandatory)]
      [AllowEmptyCollection()]
      [System.Collections.Generic.List[DgmlUtils.DirectedGraphLink]]$Links,

      [Parameter(Mandatory,ParameterSetName = 'Hashtable')]
      [ValidateNotNull()]
    [System.Collections.Hashtable]$Properties,
    
      [Parameter(Mandatory,ParameterSetName = 'Property')]
      [ValidateNotNullOrEmpty()]
    [String]$Source,
  
      [Parameter(Mandatory,ParameterSetName = 'Property')]
      [ValidateNotNullOrEmpty()]
    [String]$Target
   )

  $PSBoundParameters.Remove('Links') >$null
  $Link=New-DgmlLink @PSBoundParameters
  $Links.Add($Link) > $null
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
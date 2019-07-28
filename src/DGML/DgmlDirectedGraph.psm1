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
  #    <Node Id="Elizabeth" Category="Queen" Label="Elizabeth" Stroke="#00FFFFFF" />
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
      [String]$Target,
      
      [Parameter(ParameterSetName = 'Property')]
      [String]$Label      
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

#Todo
# https://stackoverflow.com/questions/31025704/how-to-style-give-color-link-from-group-to-generic-node
# https://ceyhunciper.wordpress.com/2010/08/21/dgml-simplified-%E2%80%93-categories/
# https://timetocode.wordpress.com/2016/07/22/graphs-and-trees-visualization-with-dgml/ (groupe)
#
#search dgml <Condition Expression
#
# #todo add Categories
# <Categories>
# <Category Id="Prince" Background="#FF0000FF" />
# <Category Id="Princess" Background="#FFFF0000" />
# <Category Id="Queen" Background="#FFFFD700" />
# </Categories>
# #todo add Properties
# <Properties>
# <Property Id="Background" Label="Background" Description="The background color" DataType="System.Windows.Media.Brush" />
# <Property Id="Label" Label="Label" Description="Displayable label of an Annotatable object" DataType="System.String" />
# <Property Id="Stroke" DataType="System.Windows.Media.Brush" />
# </Properties>
# #todo add Style With Condition
# <Styles>
# <Style TargetType="Node" GroupLabel="Queen" ValueLabel="True">
#   <Condition Expression="HasCategory(‘Queen’)" />
#   <Setter Property="Background" Value="#FFFFD700" />
# </Style>
# <Style TargetType="Node" GroupLabel="Princess" ValueLabel="True">
#   <Condition Expression="HasCategory(‘Princess’)" />
#   <Setter Property="Background" Value="#FFFF0000" />
# </Style>
# <Style TargetType="Node" GroupLabel="Prince" ValueLabel="True">
#   <Condition Expression="HasCategory(‘Prince’)" />
#   <Setter Property="Background" Value="#FF0000FF" />
# </Style>
# </Styles>

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
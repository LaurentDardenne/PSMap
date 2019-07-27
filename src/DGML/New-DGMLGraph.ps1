$code=Get-Content ..\PSMap-master\src\DGML\DmglDirectedGraph\DmglDirectedGraph\dgml.cs -Encoding UTF8 -Raw

$Asm=Add-type -TypeDefinition $code -ReferencedAssemblies System.xml.dll -PassThru
#View Enum values
if ($true -eq $false) {
    $Asm|
    Where-Object {$_.IsEnum}|
    ForEach-Object{
        Write-warning "$_"
        [System.enum]::GetValues($_)
    }
}

<#
Note
 DgmlUtils.ClrBoolean : contains true/false and True/False values
#>

#todo https://github.com/merijndejonge/Structurizr.Dgml
# https://ceyhunciper.wordpress.com/

$Graph=[DgmlUtils.DirectedGraph]::new()
#$Graph.Layout='DependencyMatrix'
$Graph.Title="Test"
  #<Nodes>
$Nodes=  New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphNode]
    $Nodes.Add([DgmlUtils.DirectedGraphNode]@{id='a'}) >$null
    #Allow duplicate data, no exception
    #$Nodes.Add([DgmlUtils.DirectedGraphNode]@{id='a'}) >$null
    $Nodes.Add([DgmlUtils.DirectedGraphNode]@{id='b'}) >$null
    $Nodes.Add([DgmlUtils.DirectedGraphNode]@{id='c'}) >$null
    #Todo transforme .svg de vscode-icon en .ico
    $node=[DgmlUtils.DirectedGraphNode]@{id='E';Group="Expanded";Shape="$PSscriptRoot\file_type_powershell.svg"} #;Shape="c:\temp\Succes.png"}
    $Nodes.Add($node)
    $node=[DgmlUtils.DirectedGraphNode]@{id='F';Group="Collapsed";Shape="$PSscriptRoot\file_type_powershell_psm.svg"}
    $Nodes.Add($node)
#todo add test to find duplicate node
# $Nodes.exists(predicate)

    #  <Links>
$Links=  New-Object System.Collections.Generic.List[DgmlUtils.DirectedGraphLink]  
$Links.Add([DgmlUtils.DirectedGraphLink]@{Source='a';Target='b'}) >$null
$Links.Add([DgmlUtils.DirectedGraphLink]@{Source='a';Target='c'}) >$null
$Links.Add([DgmlUtils.DirectedGraphLink]@{Source='a';Target='a'}) >$null
    #Allow duplicate data, no exception
#$Links.Add([DgmlUtils.DirectedGraphLink]@{Source='a';Target='b'}) >$null

$Graph.Nodes=$Nodes
$Graph.Links=$Links
XMLObject\ConvertTo-XML -Object $Graph -Filename 'C:\Temp\dgml.xml' -SerializedType 'DgmlUtils.DirectedGraph' -targetNamespace 'http://schemas.microsoft.com/vs/2009/dgml'

#dgmlimage Nuget Package
#create C:\temp\Dgml.png
& "$PSscriptRoot\dgmlimage\DgmlImage.exe" C:\temp\Dgml.xml /out:C:\temp
Invoke-Item C:\temp\dgml.png

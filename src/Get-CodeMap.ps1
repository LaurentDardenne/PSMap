#todo Pour codemap, ajouter un intermédiaire entre les différents outils de visu, codemap ne doit rien connaitre des outils il produit juste des listes de dépendances
#     Sous réserve que codemap puisse fournir les données nécessaires aux différents outils CQFD !   



$path='G:\PS\PSMap\src\'
Import-Module PSAutograph -force

Set-Location  $Path
#todo need build script
 Import-Module $Path\CodeMap\CodeMap.psd1 -force
 Import-Module $Path\Dependency\Dependency.psd1 -force
 Import-Module $Path\PSMap\PSMap.psd1 -force
 Import-Module $Path\DGML\DgmlDirectedGraph.psd1 -force


$File='..\Test\SourceCode\CommandsDependencies.ps1'
#$File='.\Test\SourceCode\NestedCall\NestedCall.ps1'
$file='..\Test\SourceCode\Imbrication1.ps1'
#$file='.\Test\SourceCode\Imbrication.ps1'
#$file='G:\PS\PSMap\src\Dependency\Dependency.psm1'
#$file='G:\PS\PSMap\Test\SourceCode\ScriptContainsOnlyStatements.ps1'
#$File='C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2\PSModule.psm1'
$file='G:\PS\PSMap\Test\SourceCode\Nested.ps1'

$CodeMap=Get-CodeMap -Path $File

#Exclue une fonction qui génére du bruit ( trop de liens) todo peut être l'ajouter une fois avec une indication ?
# -Function ne considère que les déclarations de fonction et pas tous les appels de cmdlets connue ou inconnues.

#todo  Microsoft.PowerShell.Management\Get-Process
#todo  MyModule\F1.F2.F3
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' # -Function 

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap
Show-MSaglGraph $viewer $g1 > $null

#TODO Reference count ( Metrics ?) 
# $vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
# $Lookup=New-LookupTable $funcDigraph $Vertices
# $Lookup.GetEnumerator()|Sort-Object value -Descending

#------DGML


$Graph= New-DgmlGraph -Title 'Test'
$Nodes= New-DgmlNodeList
$Links= New-DgmlLinkList 

#imbrication plutot que des liens ( sous graph)
# si une entrée définie une fonction alors le nom de l'entrée est un groupe
# todo  appels interne qui ne sont pas des fonctions, les liens externes connue comme tel script,module,dll et ressources fichier, 
#       sont palcé dans le group et peuvnet avoir un formalisme dédié (icone /et/ou couleur. DGML.Categories ?)
foreach ($current in $codemap.DiGraph.GetVertices())
{
  foreach ($Neighbor in $codemap.DiGraph.GetNeighbors($current))
  {
    if ($Neighbor.IsNestedFunctionDefinition)
    {
      Write-Debug "`tNode Group  '$($Current.Name)'"
      Add-DgmlNode -Nodes $Nodes -Properties @{id=$Current.Name;Group="Expanded";GroupSpecified=$true}
      Write-Debug "`tGroup '$($Current.Name)' contains '$($Neighbor.Name)'"
      Add-DgmlLink -Links $Links -Properties @{Category1='Contains';Source=$Current.Name;Target=$($Neighbor.Name)}
    }
    else
    { 
      Write-Debug "`tadd Node Call '$($Current.Name)' to  '$($Neighbor.Name)'"
      Add-DgmlNode -Nodes $Nodes -Properties @{id=$current.name} 
      Add-DgmlLink -Links $Links -Properties @{Source=$Current.Name;Target=$($Neighbor.Name)} 
    }
  }   

  Write-Debug "name=$($current.name) <Node Id=`"$($current.name)`" />"
  Add-DgmlNode -Nodes $Nodes -Properties @{id=$current.name} 
}

$Graph.Nodes=$Nodes
$Graph.Links=$Links
XMLObject\ConvertTo-XML -Object $Graph -Filename 'C:\Temp\dgml.xml' -SerializedType 'DgmlUtils.DirectedGraph' -targetNamespace 'http://schemas.microsoft.com/vs/2009/dgml'
copy C:\temp\dgml.xml  C:\temp\dgml.dgml      
type C:\temp\dgml.xml     

#dgmlimage Nuget Package
#create C:\temp\Dgml.png
& ".\dgml\dgmlimage\DgmlImage.exe" C:\temp\Dgml.xml /out:C:\temp
Invoke-Item C:\temp\dgml.png

#  #XML file to a C# class
#  $MyGraph=ConvertTo-Object -Filename 'G:\PS\PSMap\src\DGML\GroupForme.dgml' -SerializedType 'DgmlUtils.DirectedGraph' -targetNamespace 'http://schemas.microsoft.com/vs/2009/dgml'  -SchemaFile 'G:\PS\PSMap\src\DGML\DgmlDirectedGraph\DgmlDirectGraph\dgml.xsd'
#  $Nuspec.metadata.title='Test'
#  #A C# class to a XML file 
# ConvertTo-XML -Object $Nuspec -Filename $FileName -SerializedType 'NugetSchemas.package' -targetNamespace "http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd"
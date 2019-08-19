#todo Pour codemap, ajouter un intermédiaire entre les différents outils de visu, codemap ne doit rien connaitre des outils il produit juste des listes de dépendances
#     Sous réserve que codemap puisse fournir les données nécessaires aux différents outils CQFD !   


# $text= Get-Content $file -Encoding utf8 -raw
# @"
#  function Main {
#   Function Test-Un {
#     Function Test-One {
#     #   Function Test-Two {
#     #       & c:\temp\ScriptFull.ps1
#     #   }
#     #  Test-Two
#     }
#     Test-One
#    }
  
#    Function Test-Deux {
#     Function Test-One {
#       # Function Test-Two {
#       # }
#       #Test-Two
#     }
#     Test-One
#    }
#    Test-Un
#    Test-Deux
#  }
# #  Test-Un
# #  Test-Deux
# "@ > c:\temp\PSMmapTest.ps1

# # @"
# #  function Main {

# #    Function Test-Deux {
# #     Function Test-One {
# #       # Function Test-Two {
# #       # }
# #       #Test-Two
# #     }
# #     Test-One
# #    }
# #    Test-Un # N'existe pas -> présent
# #    Test-Deux # existe pas et la fonction aussi -> absent
# #  }
# # #  Test-Un
# # #  Test-Deux
# # "@ > c:\temp\PSMmapTest.ps1

$File='..\Test\SourceCode\CommandsDependencies.ps1'
#$File='.\Test\SourceCode\NestedCall\NestedCall.ps1'
$file='..\Test\SourceCode\Imbrication1.ps1'
#$file='.\Test\SourceCode\Imbrication.ps1'
#$file='G:\PS\PSMap\src\Dependency\Dependency.psm1'
#$file='G:\PS\PSMap\Test\SourceCode\ScriptContainsOnlyStatements.ps1'
#$File='C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2\PSModule.psm1'
#$file='G:\PS\PSMap\Test\SourceCode\Nested.ps1'
#$file='G:\PS\PSMap\Test\SourceCode\ScriptContainsOneFonctionAndOneCommand.ps1'
#$file='G:\PS\PSMap\Test\SourceCode\ScriptContainsOnlyOneFonction.ps1'
#$file='G:\PS\PSMap\Test\SourceCode\ScriptContainsOneFonctionAndOneCommandInsideParent.ps1'

$path='G:\PS\PSMap\src\'
Import-Module PSAutograph -force

Set-Location  $Path
#todo need build script
 Import-Module $Path\CodeMap\CodeMap.psd1 -force
 Import-Module $Path\Dependency\Dependency.psd1 -force
 Import-Module $Path\PSMap\PSMap.psd1 -force
 Import-Module $Path\DGML\DgmlDirectedGraph.psd1 -force

$file='..\Test\SourceCode\Imbrication1.ps1'


#ajoute un main pour porter des liens
#L'ast efface implicitement le contener portant ces liens.
$text= Get-Content $file -Encoding utf8 -raw
@"
 function Main {
 $Text
 }
"@ > c:\temp\PSMmapTest.ps1

$CodeMap=Get-CodeMap -Path c:\temp\PSMmapTest.ps1 #$File
$CodeMap=Get-CodeMap -Path $File

#Exclue une fonction qui génére du bruit ( trop de liens) todo peut être l'ajouter une fois avec une indication ?
# -Function ne considère que les déclarations de fonction et pas tous les appels de cmdlets connue ou inconnues.

#todo  Microsoft.PowerShell.Management\Get-Process
#todo  MyModule\F1.F2.F3
dbgon
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' # -Function 

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
$ObjectMap = @{
  "CommandDependency" = @{
    Follow_Property = 'CalledCommand'
     Follow_Label = 'Call'
     ID_Property = 'Name'
     Label_Property = 'Label'
  }
  "FunctionDefinition" = @{
    Follow_Property = 'FunctionDefined'
    Follow_Label = 'Define'
    ID_Property = 'Name'
    Label_Property = 'Label'
  }
  "FileDependency" = @{
    Follow_Property = 'Usedfile'
    Follow_Label = 'Depend'
    Label_Property = 'Name'
 }
}
Set-MSaglGraphObjectWithNode -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap

#Set-MSaglGraphObject -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap

#todo fullname+label -> Add node id=fullname label = shortname

#change the default layout SugiyamaLayoutSettings to Mds
$Mds= new [Microsoft.Msagl.Layout.MDS.MdsLayoutSettings]::new()
$Mds.AdjustScale= $true
$g1.LayoutAlgorithmSettings=$Mds    
Show-MSaglGraph $viewer $g1 > $null
$g=Group-FunctionGraph $FunctionGraph;$g[1].group|fl


#$Vertices= $CodeMap.Digraph.GetVertices() |% {$_}
#$Neighbors=$CodeMap.Digraph.GetNeighbors($Vertices[0])|% {$_}

#TODO Reference count ( Metrics ?) 
# $vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
# $Lookup=New-LookupTable $funcDigraph $Vertices
# $Lookup.GetEnumerator()|Sort-Object value -Descending

#------DGML


$Graph= New-DgmlGraph -Title 'Test'
$Nodes= New-DgmlNodeList
$Links= New-DgmlLinkList 

#imbrication plutot que des liens ( sous-graph)
# si une entrée, un vertex, définie un voisin de type fonction, alors le nom de l'entrée est un groupe ( sous-graph)
# todo  appels interne qui ne sont pas des fonctions, les liens externes connue comme tel script,module,dll et ressources fichier, 
#       sont placés dans le groupe et peuvent avoir un formalisme dédié (icone /et/ou couleur. DGML.Categories ?)
#       on aura donc 2 entrées, une pour porter la notion d'imbrication l'autre pour l'appel dans la fonction parente.
#        Dans ce cas c'est une présentation différente de celle affichée par Show-MSaglGraph,
#        les liens de relations étant moins prononcées, car on aura + d'imbrications de 'boites' que de liens ('fléches') entre 'boîtes'.
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
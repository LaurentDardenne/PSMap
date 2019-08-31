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

#$File='.\Test\SourceCode\NestedCall\NestedCall.ps1'
$file='..\Test\SourceCode\Imbrication1.ps1'
#$file='..\Test\SourceCode\Imbrication.ps1'
#$file='.\Dependency\Dependency.psm1'
#$file='..\Test\SourceCode\ScriptContainsOnlyStatements.ps1'
#$File='C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.2\PSModule.psm1'
#$File='C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\2.1.2\PSModule.psm1'
#$file='..\Test\SourceCode\Nested.ps1'
#$file='..\Test\SourceCode\ScriptContainsOneFonctionAndOneCommand.ps1'
#$file='..\Test\SourceCode\ScriptContainsOnlyOneFonction.ps1'
#$file='..\Test\SourceCode\ScriptContainsOneFonctionAndOneCommandInsideParent.ps1'

$path='G:\PS\PSMap\src\'
Import-Module PSAutograph -force

Set-Location  $Path
#todo need build script
 Import-Module $Path\CodeMap\CodeMap.psd1 -force
 Import-Module $Path\Dependency\Dependency.psd1 -force
 Import-Module $Path\PSMap\PSMap.psd1 -force
 Import-Module $Path\DGML\DgmlDirectedGraph.psd1 -force
. "$Path\New-DependenciesReport.ps1"

#$file='..\Test\SourceCode\Imbrication1.ps1'
$file='..\Test\SourceCode\CallMainFunctionInsideNestedFunction.ps1' #todo regrouper les cas dans un seul script
$File='..\Test\SourceCode\CommandsDependencies.ps1'
$file='G:\PS\PSMap\Test\SourceCode\Parent-Child.ps1'

#todo rechercher dans les ancêtres la présence de la commande ( on considére la dernière déclaration de la fonction)
# on  recherche dans le parent les fonctions sans récurse.On s'arrête au F° déclarées dans le Main, 
#  car on ne peut appeler une fonction imbriqué dans une autre fonction.
# oui -> on remplace le vertex avec le parent
# non -> inconnue dans le contexte ou déclarer plus avant dans la code ( dynamique)

#Add a Main function to contains orphans edge/vertex
#The ast implicitly erases the notion of container represented by the script / module
#Needed when we use 'graph node' instead 'neested blocks'
$text= Get-Content $file -Encoding utf8 -raw
@"
 function Main {
 $Text
 }
"@ > c:\temp\PSMmapTest.ps1

$CodeMap=Get-CodeMap -Path c:\temp\PSMmapTest.ps1 
$CodeMap=Get-CodeMap -Path $File

New-DependenciesReport  $CodeMap |
 Export-Document -Path $env:Temp -Format Html -Verbose

Invoke-Item "$Env:Temp\Code map dependencies.html"

#Exclue une fonction qui génére du bruit ( trop de liens) todo peut être l'ajouter une fois avec une indication ?
# -Function ne considère que les déclarations de fonction et pas tous les appels de cmdlets connue ou inconnues.

#todo  MyModule\F1.F2.F3
dbgon
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' # -Function 


$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
$ObjectMapWithLabel = @{
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
Set-MSaglGraphObjectWithNode -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMapWithLabel

#Set-MSaglGraphObject -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap


#change the default layout SugiyamaLayoutSettings to Mds
$Mds=[Microsoft.Msagl.Layout.MDS.MdsLayoutSettings]::new()
$Mds.AdjustScale= $true
$g1.LayoutAlgorithmSettings=$Mds    
Show-MSaglGraph $viewer $g1 > $null
$g=Group-FunctionGraph $FunctionGraph
$g[0].group|Select-Object Name,@{n='Define';e={$_.FunctionDefined.Name}}
$g[1].group|Select-Object Name,@{n='Call';e={$_.CalledCommand.Name}}

#todo use case : Ajout test de redéfinition de function dans la même portée.

#$Vertices= $CodeMap.Digraph.GetVertices() |% {$_}
#$Neighbors=$CodeMap.Digraph.GetNeighbors($Vertices[0])|% {$_}

#TODO Reference count ( Metrics ?) 
# $vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
# $Lookup=New-LookupTable $funcDigraph $Vertices
# $Lookup.GetEnumerator()|Sort-Object value -Descending

#------DGML


#imbrication plutot que des liens ( sous-graph)
# si une entrée, un vertex, définie une fonction (un voisin), alors le nom de l'entrée est un groupe ( sous-graph)
# todo  appels interne qui ne sont pas des fonctions, les liens externes connue comme tel script,module,dll et ressources fichier, 
#       sont placés dans le groupe et peuvent avoir un formalisme dédié (icone /et/ou couleur. DGML.Categories ?)
#       on aura donc 2 entrées, une pour porter la notion d'imbrication l'autre pour l'appel dans la fonction parente.
#        Dans ce cas c'est une présentation différente de celle affichée par Show-MSaglGraph,
#        les liens de relations étant moins prononcées, car on aura + d'imbrications de 'boites' que de liens ('fléches') entre 'boîtes'.

$Graph= New-DgmlGraph -Title 'Test'
$Nodes= New-DgmlNodeList
$Links= New-DgmlLinkList 

#TODO les liens vers l'extérieur des F° imbriquées est à revoir, car à ce jour le lien est placé sur le 'Main'.
foreach ($current in $codemap.DiGraph.GetVertices())
{
  $Label=Get-Child -Name $Current.Name
  foreach ($Neighbor in $codemap.DiGraph.GetNeighbors($current))
  {
    if ($Neighbor.IsNestedFunctionDefinition)
    {
      Write-Debug "`tNode Group  '$($Current.Name)'"
      Add-DgmlNode -Nodes $Nodes -Properties @{id=$Current.Name;Label=$Label;Group="Expanded";GroupSpecified=$true}
      Write-Debug "`tGroup '$($Current.Name)' contains '$($Neighbor.Name)'"
      Add-DgmlLink -Links $Links -Properties @{Category1='Contains';Source=$Current.Name;Target=$($Neighbor.Name)}
    }
    else
    { 
      Write-Debug "`tadd Node Call '$($Current.Name)' to  '$($Neighbor.Name)'"
      Add-DgmlNode -Nodes $Nodes -Properties @{id=$current.name;Label=$Label} 
      Add-DgmlLink -Links $Links -Properties @{Source=$Current.Name;Target=$($Neighbor.Name)} 
    }
  }   

  Write-Debug "name=$($current.name) <Node Id=`"$($current.name)`" />"
  Add-DgmlNode -Nodes $Nodes -Properties @{id=$current.name;Label=$Label} 
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
# Avoids one circular dependency, between the modules 'CodeMap' and 'dependency' 
#todo refactoring ?
#todo Pour codemap, ajouter un intermédiaire entre les différents outils de visu, codemap ne doit rien connaitre des outils il produit juste des listes de dépendances
#     Sous réserve que codemap puisse fournir les données nécessaires aux différents outils CQFD !   



$path='G:\PS\PSMap\src\'
Import-Module PSAutograph -force

Set-Location  $Path
#todo need build script
 Import-Module $Path\CodeMap\CodeMap.psd1 -force
 Import-Module $Path\Dependency\Dependency.psd1 -force
Import-Module $Path\PSMap\PSMap.psd1 -force


$File='..\Test\SourceCode\CommandsDependencies.ps1'
#$File='.\Test\SourceCode\NestedCall\NestedCall.ps1'
$file='..\Test\SourceCode\Imbrication1.ps1'
#$file='.\Test\SourceCode\Imbrication.ps1'
$file='G:\PS\PSMap\src\Dependency\Dependency.psm1'

$CodeMap=Get-CodeMap -Path $File

todo considére un appel de script comme une fonction...
#Exclue une fonction qui génére du bruit ( trop de liens) todo peut être l'ajouter une fois avec une indication ?
# -Function ne considère que les déclarations de fonction et pas tous les appels de cmdlets connue ou inconnues.
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' #-Function 

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap
Show-MSaglGraph $viewer $g1 > $null

#TODO Reference count ( Metrics ?) 
# $vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
# $Lookup=New-LookupTable $funcDigraph $Vertices
# $Lookup.GetEnumerator()|Sort-Object value -Descending
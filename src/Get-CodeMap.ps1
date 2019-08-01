# Avoids one circular dependency, between the modules 'CodeMap' and 'dependency' 
#todo refactoring ?
#todo Pour codemap, ajouter un intermédiaire entre les différents outils de visu, codemap ne doit rien connaitre des outils il produit juste des listes de dépendances
#     Sous réserve que codemap puisse fournir les données nécessaires aux différents outils CQFD !   
function Get-CodeMap {
 #Prepares the data needed to build function dependency graphs and file dependencies
 # that are external to the current file
    param(
      [string] $Path
      #todo permettre l'analyse d'un script bloc
  )  
    #Use the the fullpath name
    #todo how to define -Type ?
    #todo if path does not exist or need access rights

    $Container=New-Container -Path (Convert-Path $Path) -Type Script
    $AstParsing=Get-Ast -FilePath $Container.FileInfo.FullName
    $Dependencies= Read-Dependency -Container $Container -Ast $AstParsing.Ast


    $Parameters=@{
      Container=$Container #duplication de données avec l'objet ASTparsing ?
      Ast=$AstParsing.Ast
      DiGraph=[PSADigraph.FunctionReferenceDigraph]::New() #TODO A l'origine le graph des F° est lié à un AST
      Dependencies= $Dependencies
       #L'AST doit étre sans erreur de syntaxe.
       #Todo différencier, dans la liste d'erreur, les intructions 'using' en échec sur des modules inexistant
      ErrorAst=$AstParsing.ErrorAst
    }
    New-CodeMap @Parameters
}


$path='G:\PS\PSMap\src\'
Import-Module PSAutograph

Set-Location  $Path
Import-Module $Path\CodeMap\CodeMap.psd1 -force
Import-Module $Path\Dependency\Dependency.psm1 -force


$File='.\Test\SourceCode\CommandsDependencies.ps1'
#$File='.\Test\SourceCode\NestedCall\NestedCall.ps1'
$file='.\Test\SourceCode\Imbrication1.ps1'
#$file='.\Test\SourceCode\Imbrication.ps1'
$file='G:\PS\PSMap\src\Dependency\Dependency.psm1'

$CodeMap=Get-CodeMap -Path $File

todo considére un appel de script comme une fonction...
#Exclue une fonction qui génére du brtui ( trop de lien)
# -Function ne considère que les déclarations de fonction
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' -Function 

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap
Show-MSaglGraph $viewer $g1 > $null

#TODO Reference count ( Metrics ?) 
# $vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
# $Lookup=New-LookupTable $funcDigraph $Vertices
# $Lookup.GetEnumerator()|Sort-Object value -Descending
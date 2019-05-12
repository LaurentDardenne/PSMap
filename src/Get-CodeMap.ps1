# Avoids one circular dependency, between the modules 'CodeMap' and 'dependency' 
#todo refactoring ?
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
    $Contener=New-Contener -Path (Convert-Path $Path) -Type Script
    $Dependencies= Read-Dependency $Path
    $AstParsing=Get-Ast -FilePath $Contener.FileInfo.FullName

    $Parameters=@{
      Contener=$Contener #duplication de données avec l'objet ASTparsing ?
      Ast=$AstParsing.Ast
      DiGraph=[PSADigraph.FunctionReferenceDigraph]::New() #TODO A l'origine le graph des F° est lié à un AST
      Dependencies= $Dependencies
       #L'AST doit étre sans erreur de syntaxe.
       #Todo différencier, dans la liste d'erreur, les intructions 'using' en échec sur des modules inexistant
      ErrorAst=$AstParsing.ErrorAst
    }
    New-CodeMap @Parameters
}

IPMo G:\PS\PSAutograph\src\PSAutograph.psd1

Set-Location  G:\PS\PSMap
Import-Module G:\PS\PSMap\src\CodeMap\CodeMap.psd1 -force
Import-Module G:\PS\PSMap\src\Dependency\Dependency.psm1 -force


$File='.\Test\SourceCode\CommandsDependencies.ps1'
#$File='.\Test\SourceCode\NestedCall\NestedCall.ps1'
$file='.\Test\SourceCode\Imbrication1.ps1'
#$file='.\Test\SourceCode\Imbrication.ps1'

$CodeMap=Get-CodeMap -Path $File

todo considére un appel de script comme une fonction...
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $FunctionGraph -objectMap $ObjectMap
Show-MSaglGraph $viewer $g1 > $null

#TODO Reference count ( Metrics ?) 
# $vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
# $Lookup=New-LookupTable $funcDigraph $Vertices
# $Lookup.GetEnumerator()|Sort-Object value -Descending
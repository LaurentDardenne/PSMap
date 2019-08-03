#PSMap.psm1
#todo Gestion d'alias. Recherche dans un cache. PSSA : Helper.Instance.GetCommandInfoLegacy(cmdName)

$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\PSMapLog4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params

#Chaque nom de clé est un nom de type d'un objet à traiter, sa valeur est une hashtable possédant les clés suivantes :
# Follow_Property  : est un nom d'une propriété d'un objet, son contenu pouvant pointer sur un autre objet (de même type ou pas) ou être $null
# Follow_Label     : libellé de la relation (arête/edge) entre deux noeuds (sommet/vertex) du graphe
# Label_Property   : Nom de la propriété d'un objet contenant le libellé de chaque noeud (sommet) du graphe
#
#Need PSAutograph module, wrapper for MSagl (Microsoft Automatic Graph Layout)
$ObjectMap = @{
  "FunctionDependency" = @{
     Follow_Property = 'CalledFunction'
     Follow_Label = 'Call'
     Label_Property = 'Name'
  }
  "FunctionDefinition" = @{
    Follow_Property = 'FunctionDefined'
    Follow_Label = 'Define'
    Label_Property = 'Name'
  }
  "FileDependency" = @{
    Follow_Property = 'Usedfile'
    Follow_Label = 'Depend'
   Label_Property = 'Name'
 }
}

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

  # todo revoir : déplacer ici la f° dependency\New-Container 
  # todo les dependance Read-Dependency -Container $Container
  #   #todo 
    #La notion de contener dans les dependencies n'est utilisé car la structure codemap le connait et
    # on ne génère la vue qu'à la fin de l'analyse on connait donc encore le contener.

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

function New-CodeMapInformation{
  #Uses the parameters of the ConvertTo-FunctionObjectMap function.
  param(
    [string] $Path,

    #Only consider function declarations, commands called unknown are not shown in the result.
    [Switch] $Function,

      #To exclude functions that generate noise in the display of the graph.
    [string[]] $Exclude=@()
  )
  Function NewCodeMapInformation{
    #certaines info de map peuvent ne pas exister
    param(
             [Parameter(Mandatory=$True,position=0)]
            $CodeMap,
             [Parameter(Mandatory,position=1)]
            $FunctionsMap,
             [Parameter(Mandatory,position=2)]
            $DependenciesMap,
             [Parameter(Mandatory,position=3)]
            $RessourcesMap
    )
    
      [pscustomobject]@{
        PSTypeName='NewCodeMapInformation';
        CodeMap=$CodeMap;
        FunctionsMap=$FunctionsMap;
        DependenciesMap=$DependenciesMap;
        RessourcesMap=$RessourcesMap;
       }
    }# NewCodeMapInformation
  
$CodeMap=Get-CodeMap -Path $File

#todo considére un appel de script comme une fonction...
#-Exclude  exlue les  fonction qui générent du bruit ( trop de liens) todo peut être l'ajouter une fois avec une indication ?
# -Function ne considère que les déclarations de fonction et pas tous les appels de cmdlets connue ou inconnues.
$FunctionGraph=ConvertTo-FunctionObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' #-Function 
#todo $DependencyGraph=ConvertTo-DependencyObjectMap -CodeMap $CodeMap -Exclude 'Write-Log' #-Function
#$RessourceGraph
NewCodeMapInformation $CodeMap $FunctionGraph #$DependencyGraph $RessourceGraph
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip

# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }

Export-ModuleMember -Function * -Variable 'ObjectMap'
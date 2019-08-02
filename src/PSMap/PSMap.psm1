#PSMap.psm1

$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\PSMapLog4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params


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

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip

# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }
#Export-ModuleMember -Function * -Variable 
#CodeMap.psm1

$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4Net}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\CodeMapLog4Net.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
  Scope='Script'
}
&$InitializeLogging @Params


Function New-CalledCommand{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
        
        [Parameter(Mandatory=$True,position=1)]
        $Label,
        
        [Parameter(position=2)]
        $Container,

         [Parameter(position=3)]
        $CalledCommand=$null
    )

    Write-Debug "CalledCommand $name -> $CalledCommand label -> $Label"
    [pscustomObject]@{
      PSTypeName='CommandDependency';
      Name=$Name;
      Label=$Label
      Container=$Container;
      CalledCommand=$CalledCommand
    }
}
Function New-FunctionDefinition{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,

        [Parameter(Mandatory=$True,position=1)]
        $Label,

        [Parameter(position=2)]
        $Container,

        [Parameter(position=3)]
         $FunctionDefined=$null
    )
  
    Write-Debug "FunctionDefinition  $name -> $FunctionDefined label -> $Label"
    [pscustomObject]@{
      PSTypeName='FunctionDefinition';
      Name=$Name;
      Label=$Label
      Container=$Container;
      FunctionDefined=$FunctionDefined
    }
}

Function New-FileDependency{
    param(
         [Parameter(Mandatory=$True,position=0)]
        $Name,
         [Parameter(position=1)]
        $Usedfile=$null
    )
  
    Write-Debug "FileDependency  $name -> $UsedFile"
    [pscustomObject]@{
      PSTypeName='Usedfile';
      Name=$Name;
      Usedfile=$Usedfile
    }
}


Function ConvertTo-Vertex {
  # return an array of PSADigraph.Vertex
      param (
        #AST Visitor
        [PSADigraph.FunctionReferenceDigraph] $funcDigraph,
  
        [System.Management.Automation.Language.ScriptBlockAst] $Ast
      ) 
    $Ast.Visit($funcDigraph)
    $funcDigraph.GetVertices() #Vertex=function name
}

function Get-Parent {
  #return the parent of a vertex : GrandParent.Parent.Child -> GrandParent.Parent
  param ($name)
 
  $Pos=$Name.LastIndexOf('.')
 if ($Pos -eq -1) 
 {return $null}
 else
 {return $Name.Remove($Pos)}
}

function Get-Child {
  #return the last part of a vertex name : GrandParent.Parent.Child -> Child
  param ($name)
 
  $Index=-1; #Last part of a name 
  try {
    $Result=$Name.Split('.')[$Index] 
  }
  catch [System.IndexOutOfRangeException]
  { $Result=$null }
  Return $Result 
}


function ConvertTo-FunctionObjectMap {
  #Renvoit 2 type d'objets:
  # une définition de fonction et les appels de commande (ce peut être une fonction) contenus dans cette définition.
  # Le propriétaire/conteneur est le script analysé.
  param (
      # To retrieve the Vertices list build by a PSADigraph.FunctionReferenceDigraph instance.
      $CodeMap,
       
      #Only consider function declarations, commands called unknown are not shown in the result.
      [Switch] $Function,

       #To exclude functions that generate noise in the display of the graph.
      [string[]] $Exclude=@(),

       #To exclude runtime command: $CmdInfo.Source -notmatch '^Microsoft\.PowerShell\.'
      [switch] $noRuntime
  ) 
 function Remove-RuntimeCommand  {
   #todo Sauf celle de portant des info de ressources (I/O) et de dépendances de code
   param (
    $Vertices
   )
    #todo cache des commandes connue et inconnues (cmd.Unknown=$true)
    #todo cache des fontions du runtime, dans ce cas  : (Dir function:Clear-Host).HelpFile pointe sur ‘System.Management.Automation.dll-Help.xml’
   foreach ($Vertex in $Vertices)
   {
     try {
      $CmdInfo=Get-Command $Vertex.Name -ErrorAction Stop
      If ($CmdInfo.Source -notmatch '^Microsoft\.PowerShell\.') #todo celle préfixée Modulename\Cmdname ?
      { write-Output $Vertex }  
     } catch [System.Management.Automation.CommandNotFoundException] {
      write-Output $vertex #todo cache
     }
   }
  }
   #Here, one  vertex is a the function name
  $Vertices= $CodeMap.Digraph.GetVertices() 

   # On filtre à chaque appel
  if ($noRuntime)
  { $Vertices=Remove-RuntimeCommand $Vertices}
  $Container=$CodeMap.Container
   
  if ($Vertices.Count -eq 0)
  { 
     #Le script doit contenir au moins une commande ou une définition de fonction
    Write-Verbose "The code container do not has neither command nor function definition."
    return
  }

  foreach ($vertex in $Vertices )
  {  
    if ($Function -and ($Vertex.Ast -isnot [System.Management.Automation.Language.FunctionDefinitionAst]))
    { 
       Write-Debug "-Function Vertex ($($vertex.name)' is not a fonction $($Vertex.Ast.gettype())" 
       continue 
    }

    # les noms de commande contenant des noms de fichier doivent être en entier sinon on coupe sur l'extension '.ps1'
    #le label doit venir du vertex
    $CurrentFunctionName=$Vertex.Name    
    if ($CurrentFunctionName -in $Exclude)
    { continue }
    Write-Debug "main $CurrentFunctionName type $($Vertex.ast.Gettype().fullname)" 
    Write-Debug "`t has '$($CodeMap.Digraph.GetNeighbors($Vertex).count)' neighbors"
    $LabelFunction=Get-Child -Name $CurrentFunctionName   #Simple name of a function
    if ($Vertex.Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] )
    {
        Write-Debug "`t $($Parent.Name) define $CurrentFunctionName" 
        $Parent=Get-Parent -Name $CurrentFunctionName #Full name defining the nesting of calls
        if (($null -ne $Parent) -and ($Parent -ne $CurrentFunctionName))
        { 
          $LabelParent=Get-Child -Name $Parent
          New-FunctionDefinition -Name $Parent -Label $LabelParent -Container $Container -FunctionDefined @(New-FunctionDefinition -Name $CurrentFunctionName -Label $LabelFunction) 
        }
        else
        { New-FunctionDefinition -Name $CurrentFunctionName -Label $LabelFunction}
    }
    else 
    {
        Write-Debug "`tCall '$( $CurrentFunctionName)'' type $($Vertex.Ast.Gettype().fullname)"
        New-CalledCommand -Name $CurrentFunctionName -Label $LabelFunction -Container $Container
    }

    if ($noRuntime)
    { $Neighbors=Remove-RuntimeCommand $CodeMap.Digraph.GetNeighbors($Vertex) } #Todo SHORT NAME
    else
    { $Neighbors=$CodeMap.Digraph.GetNeighbors($Vertex) }

    foreach ($CommandCalled in $Neighbors )
    {
      Write-Debug "Neighbors $CommandCalled" 

      if ($Function -and  ($CommandCalled.Ast -isnot [System.Management.Automation.Language.FunctionDefinitionAst]))
      { continue }
      
      $CurrentCommandName=$CommandCalled.Name  
      if ($CurrentCommandName -in $Exclude)
      { continue }
      $LabelCommand=Get-Child -Name $CurrentCommandName
      Write-Debug "`tCall $CurrentCommandName type $($CommandCalled.Ast.Gettype().fullname)"
      Write-Debug "`t'$CurrentFunctionName' Call '$CurrentCommandName'"
      New-CalledCommand -Name $CurrentFunctionName -Label $LabelFunction -Container $Container -CalledCommand @(New-CalledCommand -Name $CurrentCommandName -Label $LabelCommand)
    }
  }  
}

function New-LookupTable {
  #Contains the occurrence number of a function
  param( 
    [PSADigraph.FunctionReferenceDigraph] $funcDigraph,

    [PSADigraph.Vertex[]] $Vertices
 )
  Function Add-Name {
    param( $Name )
      if ($LookupTable.ContainsKey($Name))
      { $LookupTable.$Name++ }
      else
      { $LookupTable.Add($Name,0) }
  }       

  $LookupTable=@{}

  foreach ($Vertex in $Vertices) 
  {
    Add-Name $Vertex.Name
    foreach ($CommandCalled in $funcDigraph.GetNeighbors($Vertex) )
    { Add-Name $CommandCalled.Name }
    
  }
  return ,$LookupTable
}

Function New-CodeMap{
    param(
          [Parameter(Mandatory=$True,position=0)]
        $Container,
          [Parameter(Mandatory=$True,position=1)]
        $Ast,
          [Parameter(Mandatory=$True,position=2)]
        $DiGraph,
          [Parameter(position=3)]
        $Dependencies,
          [Parameter(position=4)]
        $ErrorAst
    )
    
     #search the functions to fill the digraph
    $Ast.Visit($Digraph)
  
    [pscustomobject]@{
      PSTypeName='CodeMap';
      Container=$Container;
      Ast=$Ast;
      DiGraph=$DiGraph;
      Dependencies=$Dependencies;
      ErrorAst=$ErrorAst
    }
}# New-CodeMap

function Group-FunctionGraph{
  param ($FunctionGraph)
  $FunctionGraph|
   Group-Object @{e={$_.pstypenames[0]}}
}

function Format-FunctionGraph{
  param ($FunctionGraph)
  $FunctionGraph|
   Group-Object @{e={$_.pstypenames[0]}}|
   Format-List -GroupBy Name
}

Function OnRemove {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemovePsIonicZip

# Section  Initialization
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemove }
  
Export-ModuleMember -Function *
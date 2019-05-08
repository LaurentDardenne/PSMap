function Get-CodeMap {
    param(
      [string] $Path
  )  
  
    $Parameters=@{
      Contener=New-Contener -Path (Convert-Path $Path) -Type Script
      Ast=Get-Ast -FilePath $Path
      DiGraph=[PSADigraph.FunctionReferenceDigraph]::New()
      Dependencies= Read-Dependency $Path
    }
      #todo doit étre sans erreur de syntaxe
      #différencier, dans la liste d'erreur, les intructions 'using' en échec sur des modules inexistant
      #try {
        #create $global:ErrorsAst list
        #using peut être créer des erreur mais l'ast est utilisable
    #$Ast=Get-Ast -FilePath $Path
        #  if ( (Get-Variable $ErrorsList).Value.Count -gt 0  )
        #  {
        #     $Er= New-Object System.Management.Automation.ErrorRecord(
        #             (New-Object System.ArgumentException("The code contains syntax errors.")), 
        #             "InvalidSyntax", 
        #             "InvalidData",
        #             "[AST]"
        #            )  
      
        #     $PSCmdlet.WriteError($Er)
        #  }
        # } catch [System.ArgumentException] {
        #   if ($_.FullyQualifiedErrorId -eq 'InvalidSyntax,Get-AST')
        #   { Write-debug "$ErrorsAst"}
        # }      
  
    New-CodeMap @Parameters
}

Get-CodeMap 
$funcDigraph = [PSADigraph.FunctionReferenceDigraph]::New()
$CodeMap=ConvertTo-FunctionObjectMap  $funcDigraph $sb
#$CodeMap=ConvertTo-ObjectMap  $funcDigraph $File.Scriptblock -Exclude @('Evolution-Log') -Function

$viewer = New-MSaglViewer
$g1 = New-MSaglGraph
Set-MSaglGraphObject -Graph $g1 -inputobject $CodeMap -objectMap $ObjectMap
$resultModal=Show-MSaglGraph $viewer $g1

#Reference count ( Metrics ?) TODO
$vertices=ConvertTo-Vertex $funcDigraph $File.Scriptblock
$Lookup=New-LookupTable $funcDigraph $Vertices
$Lookup.GetEnumerator()|Sort-Object value -Descending
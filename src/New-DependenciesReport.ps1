
Function New-DependenciesReport{
  param(
    $codemap
  )

$DependenciesGroups= Group-Dependency $codemap.Dependencies

#Columns table for PScribo report
$Properties=@{
    'Microsoft.PowerShell.Commands.ModuleSpecification'=@('Name','Version')
    'NamespaceDependency'=@('Name','Version')
    'InformationScript'=@('FileInfo')
    'ProcessStaticParameterBinder'=@('FilePath')
    'Selected.System.Management.Automation.ApplicationInfo'=@('Name','Source')
    'AddTypeStaticParameterBinder'=@('Path','LiteralPath','AssemblyName')
    'DLLDependency'=@('Name')
}

Document 'Code map dependencies' {

 Paragraph -Style Heading1 'Dependencies'
 Paragraph -Style Heading3 $CodeMap.Container.FileInfo.Name
 Paragraph 'List of dependencies'

 $DependenciesGroups|
  ForEach-Object {
    $Typename=$_.Name
    Section -Style Heading1 $TypeName {
       Section -Style Heading2 'Autofit Width Autofit Cell No Highlighting' {
           Paragraph -Style Heading3 'Example of an autofit table width, autofit contents and no cell highlighting.'
           Paragraph "Dependencies ($($_.Count) found):"
           $_.Group | Table -Columns $Properties.$TypeName  -Headers $Properties.$TypeName -Width 0
       }
    }#Section
  }# $DependenciesGroups
 } #Document
}
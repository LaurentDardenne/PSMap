#digraph ne connait que la fonction, et on ne peut avoir qu'une seule entrée de même nom
#Ici on ne peut donc avoir la définition et l'appel
# première référence de fonction 'name' -> add AST F° : function:Name
# second référence 'Callname', un appel -> recherche function:Callname 
function Set-FileWrong
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Path to file
        [Parameter(Mandatory=$true)]
        $Path
    )
     'test'
}
Set-FileWrong -Path 'c:\'

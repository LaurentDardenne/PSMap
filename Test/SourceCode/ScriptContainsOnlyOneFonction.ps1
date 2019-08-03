function Set-FileWrong
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Path to file
        [Parameter(Mandatory=$true)]
        $Path
    )
    # function test {}
     "String" | Out-File -FilePath $FilePath
}
dir |ForEach-Object {$_.name}
Set-FileWrong

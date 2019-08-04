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

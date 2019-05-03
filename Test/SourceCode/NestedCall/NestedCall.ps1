Write-warning "Call a script"
.\One.ps1
&'.\One.ps1'
#&'C:\Prive\Modules\PSMap\Test\SourceCode\NestedCall\One.ps1'
Write-warning "Call a dotsourced script"
. .\Two.ps1
Function Get-NestedCall {
    Write-warning "script NestedCall -function Get-NestedCall"
}
#todo Import-Module
Import-module .\Two.ps1
#Requires -Modules @{ ModuleName="AzureRM.Netcore"; ModuleVersion="0.12.0" }
#Requires -Modules Pester

import-module @{ ModuleName="AzureRM.Netcore"; ModuleVersion="0.12.0" }
import-module @{ ModuleName = 'Computer'; ModuleVersion = '1.0'; GUID = 'a5d7c151-56cf-40a4-839f-0019898eb324' }
import-module Log4posh
import-module -Name Log4posh
import-module -FullyQualifiedName @{ModuleName = 'Computer'; ModuleVersion = '1.0'; GUID = 'a5d7c151-56cf-40a4-839f-0019898eb324'}
import-module PSake,Pester
import-module C:\temp\Modules\PSake.psd1
import-module C:\temp\Modules\Pester.psm1
import-module -Name C:\temp\Modules\Pester.psm1

IPMO @{ ModuleName="AzureRM.Netcore"; ModuleVersion="0.12.0" }
IPMO @{ ModuleName = 'Computer' ;ModuleVersion = '1.0'; GUID = 'a5d7c151-56cf-40a4-839f-0019898eb324'}
IPMO Log4posh
IPMO -Name Log4posh
IPMO -FullyQualifiedName @{ ModuleName = 'Computer' ;ModuleVersion = '1.0'; GUID = 'a5d7c151-56cf-40a4-839f-0019898eb324' }
IPMO PSake,Pester
IPMO C:\temp\Modules\PSake.psd1
IPMO C:\temp\Modules\Pester.psm1
IPMO -Name C:\temp\Modules\Pester.psm1

. .\MonScriptDot.ps1
& .\MonScriptAmperSand.ps1

. C:\temp\Modules\MonScriptDor.ps1
& C:\temp\Modules\MonScriptAmperSand.ps1

. ..\MonScriptDot.ps1
& ..\MonScriptAmperSand.ps1

. .\MonScriptDot.ps1 -Path c:\temp\f.csv
& .\MonScriptAmperSand.ps1 -Path c:\temp\f.csv

. C:\temp\Modules\MonScriptDot.ps1 -strict
& C:\temp\Modules\MonScriptAmperSand.ps1 -strict

. ..\MonScriptDot.ps1 -Verbose -Debug
& ..\MonScriptAmperSand.ps1 -Verbose -Debug

Start-Process msiexec.exe -ArgumentList "/X {000000C57B8D-16EB-4FD4-959E-F868BF96E867} /qn /norestart" -wait
Start-Process "$Path\Prg.exe" -ArgumentList " /p1=data_01 /Timeout=5 " 
Start-Process ipconfig.exe /release -wait

Start msiexec.exe -ArgumentList "/X {000000C57B8D-16EB-4FD4-959E-F868BF96E867} /qn /norestart" -wait
Start "$Path\Prg.exe" -ArgumentList " /p1=data_01 /Timeout=5 " 
Start ipconfig.exe /release -wait

saps msiexec.exe -ArgumentList "/X {000000C57B8D-16EB-4FD4-959E-F868BF96E867} /qn /norestart" -wait
saps "$Path\Prg.exe" -ArgumentList " /p1=data_01 /Timeout=5 " 
saps ipconfig.exe /release -wait

TASKKILL /F /IM Vulscan.exe /T
TASKKILL.exe /F /IM Vulscan.exe /T


Add-Type -path C:\temp\MyAssembly.dll
Add-Type -LiteralPath C:\temp[0]\MyAssembly.dll
Add-Type -AssemblyName "System.Windows.Forms"
Add-Type -AssemblyName "Accessibility"
#todo ReferencedAssemblies

[System.Reflection.Assembly]::LoadFrom($dllpath)
$assembly = [Reflection.Assembly]::LoadFile("c:\path\file.dll")

#GetCommandeName -eq $null
& $foo
& (gmo SomeModule) Bar
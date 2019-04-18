#Requires -Modules @{ ModuleName="AzureRM.Netcore"; ModuleVersion="0.12.0" }
#Requires -Modules @{ ModuleName="AzureRM.Netcore"; Requiredversion="0.13.0"; GUID = 'a5d7c151-56cf-40a4-839f-0019898eb324'}
#Requires -Modules Pester

#v5
#Resources used by the using statement must exist
using assembly System.Windows.Forms
using namespace System.Windows.Forms

Using module Pester
Using module @{ ModuleName="Pester"; ModuleVersion="4.7.3" }
Using module 'C:\Program Files\WindowsPowerShell\Modules\Pester\4.7.3\Pester.psd1'

Import-module c:\temp\modules\my.dll
Import-module c:\temp\my.ps1

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

TASKKILL /F /IM Vscan.exe /T
TASKKILL.exe /F /IM Vscan.exe /T


Add-Type -path C:\temp\MyAssembly.dll
Add-Type -LiteralPath C:\temp[0]\MyAssembly.dll
Add-Type -AssemblyName "System.Windows.Forms"
Add-Type -AssemblyName "Accessibility"
Add-Type -TypeDefintion $Source -Language CSharp -Verbose -PassThru -ReferencedAssemblies $requiredAssembly
Add-Type -TypeDefintion $Source -Language CSharp -Verbose -PassThru -ReferencedAssemblies 'C:\temp[0]\MyAssembly.dll'

[System.Reflection.Assembly]::LoadFrom("c:\path\file.dll")
[System.Reflection.Assembly]::LoadFrom($dllpath)

$assembly = [Reflection.Assembly]::LoadFile("c:\path\file.dll")
$assembly = [Reflection.Assembly]::LoadFile($dllpath)

[System.Reflection.Assembly]::UnsafeLoadFrom("c:\path\file.dll")
[System.Reflection.Assembly]::UnsafeLoadFrom($Dllpath)

 #Deprecated
[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
 #Deprecated
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

[System.Reflection.Assembly]::LoadFrom($dllpath)
$assembly = [Reflection.Assembly]::LoadFile("c:\path\file.dll")

#GetCommandeName() -eq $nul|
& $foo
& (gmo SomeModule) Bar
<# todo
$exe = "H:\backup\scripts\vshadow.exe“
&$exe -p -script=H:\backup\scripts\vss.cmd E: M: P:
&"C:\Program Files (x86)\Notepad++\notepad++.exe"
&"H:\backup\scripts\sbrun.exe" --% -mdn etc
#>
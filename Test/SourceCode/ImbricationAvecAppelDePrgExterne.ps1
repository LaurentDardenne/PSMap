$sb={
    #the parser cannot know which command is executed,GetCommandName() retunr null 
   & $foo 
   & (gmo SomeModule) 
   $exe = "H:\backup\scripts\vshadow.exe"
   &$exe -p -script=H:\backup\scripts\vss.cmd E: M: P:
   notepad.exe C:\Temp\test.txt
   &"C:\Program Files (x86)\Notepad++\notepad++.exe"
   &"H:\backup\scripts\sbrun.exe" --% -mdn etc  
     
   function Get-TypeName {
    param($pv0)
    'Inside Scriptblock global'
   }

  function Convert-Object{
      [CmdletBinding()]
      [OutputType([String])]
      Param
      (
          [Parameter(Mandatory=$true)]
          $InputObject
      )
    
    function Get-TypeName {
      param()
      'Inside Convert-Object'
    }
    
    function MethodHeader {
      param()
      $type=Get-TypeName
      return $type
    }
    
    function MethodHeader2 {
      param()
        function Get-TypeName {
          param($Pv1)
          'Inside MethodHeader2 première déclaration'
        }
      function Get-TypeName {
          param($Pv2)
          Get-TypeName -pv1    #existe pour la recherche mais est incohérent dans ce contexte car une seule function de ce nom existe !!
          'Inside MethodHeader2 sesonde déclaration'
        }

      $type=Get-TypeName -pv2
      return $type
    }
    MethodHeader
    MethodHeader2
  }#Convert-Object
  Get-TypeName -pv0
  
}  
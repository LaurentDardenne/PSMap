$sb={
notepad.exe C:\Temp\test.txt
. .\ScriptRelatif.ps1
Import-module test

Function Test-Three {
  Function Test-One {
    Function Test-Two {
        & c:\temp\ScriptFull.ps1
    }
   Test-Two
  }
  Test-One
 }

 Function Test-Three2 {
  Function Test-One {
    Function Test-Two {
        & c:\temp\ScriptFull.ps1
    }
   Two
  }
  One
 }

#Imbrication ET dans le même scope
Function Test-NestedThree {


  Function Test-NestedOne {
    Import-module c:\Module\test\test.psd1
  }

  Function Test-NestedTwo {
    Import-module c:\Module\test\test.psd1
  }
  
  #TODo
  #si NestedOne on retrouve le nom de commande mais pas si Test-NestedOne qui est une définition
  Test-NestedOne
  Test-NestedTwo
  notexist
  Import-module c:\Module\test\test.psd1
}

#dans le même scope
Function Test-OneStandAlone {
}

Function Test-TwoStandAlone {
}

Function Test-ThreeStandAlone {
  oneStandAlone 
  twoStandAlone
}

#Appel externe
Function Test-Four {
    Function Test-Inner {
     TwoExternal
  }
  OneExternal
 }
}
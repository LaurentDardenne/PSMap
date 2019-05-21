$sb={
  Function Test-NestedThree {


    Function Test-NestedOne {
      Import-module c:\Module\test\test.psd1
    }
  
    Function Test-NestedTwo {
      Import-module c:\Module\test\test.psd1
    }
    
    #TODO
    #si NestedOne on retrouve le nom de commande mais pas si Test-NestedOne qui est une définition
    Test-NestedOne1
    Test-NestedTwo2
    notexist
    Import-module c:\Module\test\test.psd1
  }

}

$sb={
  Function Test-NestedThree {


    Function Test-NestedOne {
      Import-module c:\Module\test\test.psd1
    }
  
    Function Test-NestedTwo {
      Import-module c:\Module\test\test.psd1
    }
    
    #TODO
    #si NestedOne on retrouve le nom de commande mais pas si Test-NestedOne qui est une définition
    Test-NestedOne
    Test-NestedTwo
    notexist
    Import-module c:\Module\test\test.psd1
  }

}
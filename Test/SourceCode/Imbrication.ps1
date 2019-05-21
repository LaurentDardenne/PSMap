$sb={
Function Test-Three {
  Function Test-One {
    Function Test-Two {
    }
   Test-Two
  }
  Test-One
 }

 Function Test-Three2 {
  Function Test-One {
    Function Test-Two {
    }
   Two
  }
  One
 }

#Imbrication ET dans le même scope
Function Test-NestedThree {


  Function Test-NestedOne {
  }

  Function Test-NestedTwo {
  }
  
  #TODo
  #si NestedOne on retrouve le nom de commande mais pas si Test-NestedOne qui est une définition
  Test-NestedOne
  Test-NestedTwo
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
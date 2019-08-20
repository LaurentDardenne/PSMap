#Note:
#Dans l'AST une classe est portée par System.Management.Automation.Language.TypeDefinitionAst
#
#Les méthodes d'une classe PS sont implémentées via une définition de fonction
#Note : La classe System.Management.Automation.Language.FunctionMemberAst contient un membre privée de type FunctionDefinitionAst
#
# $Functions = $AST.FindAll({
#    param($ast)
#     $ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
#     $ast.parent -isnot [System.Management.Automation.Language.FunctionMemberAst]
#    },$true)


Function Show {
    param()
    Write-output "Outside of the class"
}

Class Test { 
   Test() { 
       Write-warning "Call constructeur par défaut" 
   } 
  
   [void] Show() { 
       Write-Host "Méthode Show" 
   }
}

$C=[Test]::new()

Show
$C.Show()

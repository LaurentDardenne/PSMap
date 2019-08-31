Function Main {
    Function One {Two}
    Function Two {Four}
    Function Three {Two}
    Function Four {Five}
    Function Five {}
    
    One
    Two
}
# $vertices=$CODEMAP.DiGraph.GetVertices()|? {$_}
# $vertices|% {$CODEMAP.DiGraph.GetNeighbors($_)|? {(get-child $_.name) -eq 'Two'}}

# Name           Ast                 IsNestedFunctionDefinition
# ----           ---                 --------------------------
# Main.Two       Function Two {Four}                       True
# Main.One.Two   Two                                      False
# Main.Three.Two Two                                      False

#Pour IsConnected
# $vertices|% {$CODEMAP.DiGraph.GetNeighbors($_)|? {$CODEMAP.DiGraph.IsConnected($_,$v)}} 
#Todo A ce jour (29/08/19) les noms de fonction complét étant différent pour occurence on ne peut les retrouver
# TODO à partir d'une fonction qui l'appelle et qui appelle-t-elle
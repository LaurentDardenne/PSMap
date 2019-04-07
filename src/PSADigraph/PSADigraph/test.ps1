cd G:\PS\PSMap\src\PSADigraph\PSADigraph\bin\Debug\
add-type -path .\PSADigraph.dll
$f=[PSADigraph.FunctionReferenceDigraph]::new()
type  "$env:temp\PSADigraph.log"


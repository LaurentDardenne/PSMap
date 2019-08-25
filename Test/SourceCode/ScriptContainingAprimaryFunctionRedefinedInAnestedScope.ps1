function Main {
  Function OutScope{ param($s) Write-host "Main.OutScope from $s"}
# Ps prend la dernière définition de fonction en cours (enregistrée dans le provider)
  Function Test-Un {
    OutScope 'Test-Un avant redéfinition'
    Function Test-One { Write-host "Main.Test-un.Test-One-Call outScope";  OutScope 'Test-One' }
    Test-One

#todo redéfinition via dotsource ou un module

    Function OutScope { param($s)  Write-host "Main.Test-Un.OutScope from $s" }
    Test-One     
    OutScope 'test-un après  définition' 
  }
  OutScope MainBefore
  Test-Un
  OutScope mainAfter
}
main
  
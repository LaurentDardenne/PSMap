Function Test-One {
  # Function Test-zero {
  #   un
  #   deux
  #   trois
  # }
  Function Test-Two {
    Function Test-Three {
        & c:\temp\ScriptFull.ps1
    }
   Test-Three
  }
  Test-Two
 }
test-one

#  Function Test-Four{
#   Function Test-Two {
#     Function Test-Three {
#         & c:\temp\ScriptFull.ps1
#     }
#    Two
#   }
#   One
#  }

#  Function Test-Zero {
  
#  }

 
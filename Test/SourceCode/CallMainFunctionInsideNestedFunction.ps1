function Get-Main{
   function nestedOne {
      function nestedTwo{
         Get-MyDatas #faux : Main.Get-Main.nestedOne.nestedTwo  call ---> Main.Get-Main.nestedOne.nestedTwo.Get-MyDatas
      }
      nestedTwo 
   }
nestedOne
}
function set-datas {
   Get-MyDatas #faux : Main.set-datas  call ---> Main.set-datas.Get-MyDatas
} 

function Get-MyDatas{
} 

Get-Main

##Remove-AU-Registry.ps1
try{
    reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
}catch{
    exit 0
}
reg delete HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /f
exit 0
$localprograms = choco list --localonly
if ($localprograms -like "*java*")
{
    choco upgrade jre8 -y
}
Else
{
    choco install jre8 -y
}
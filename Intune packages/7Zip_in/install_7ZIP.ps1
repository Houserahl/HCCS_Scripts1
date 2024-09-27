$localprograms = choco list --localonly
if ($localprograms -like "*7-zip*")
{
    choco upgrade 7zip.install -y
}
Else
{
    choco install 7zip.install -y
}
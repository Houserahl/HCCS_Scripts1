$Users = Import-CSV "C:\Temp\Groups.csv"

ForEach($User in $Users)
{

New-DistributionGroup -Name $user.Name -Alias $user.Alias -PrimarySmtpAddress $user.PrimarySmtpAddress -DisplayName $user.DisplayName -RequireSenderAuthenticationEnabled:$False -IgnoreNamingPolicy

}
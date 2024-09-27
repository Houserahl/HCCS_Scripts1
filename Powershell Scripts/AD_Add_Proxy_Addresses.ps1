Import-Module ActiveDirectory

$domain1 = "sample1.org"
$domain2 = "sample1.onmicrosoft.com"
$domain3 = "o365.sample1.org"

$users = Get-ADUser -Filter * -Properties mail

foreach ($user in $users)
{

	$email = $user.mail
	
	if($email -match "^(.+)@(.+)$")
	{
		$username = $matches[1]
		$defaultEmail = "$username@$domain1"
		$onMicrosoftEmail = "$username@$domain2"
		$o365Email = "$username@$domain3"
		
		$user.ProxyAddresses += "SMTP:$defaultEmail"
		$user.ProxyAddresses += "smtp:$onMicrosoftEmail"
		$user.ProxyAddresses += "smtp:$o365Email"
		
		Set-ADUser -Instance $user
	}
	else
	{	
		Write-Host "No valid email address found."
	}
}
	
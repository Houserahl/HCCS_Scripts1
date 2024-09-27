#This shows the MFA methods configured - "MFATypes" - the (legacy) state for a user, and the default method configured .

# Shows only licensed, enabled users.

#Check for MSOnline module
$Modules=Get-Module -Name MSOnline -ListAvailable
if($Modules.count -eq 0)
{
  Write-Host  Please install MSOnline module using below command: `nInstall-Module MSOnline  -ForegroundColor yellow
  Exit
}
#Connect to MSOnline
Connect-MsolService | Out-Null
#Get default domain
$domainName = ((Get-MsolDomain) | ?{$_.isDefault -eq "TRUE"}).Name
#Name of Output file
$ExportCSV=".\$($domainName)_MFAEnrollmentStatus_$((Get-Date -format yyyy-MMM-dd` HH-mm).ToString())_licensedAndEnabledOnly.csv"
Get-MsolUser -All | ?{$_.isLicensed -eq $True -and $_.BlockCredential -eq $False} | foreach{
	#Determine MFA State (i.e. Disabled, Enabled, Enabled via Conditional Access, Enforced
	$MFAStatus = $_.StrongAuthenticationRequirements.State
	#If empty, then disabled
	If (!$MFAStatus){
		$MFAStatus = "Disabled"
	} 
	#Determine default MFA method for user if not disabled
	$MFADefault = ($_.StrongAuthenticationMethods | where {$_.IsDefault -eq "True"}).MethodType
	#If empty, MFA needs to be set up by user
	If (!$MFADefault -and $MFAStatus -ne "Disabled"){
		$MFADefault = "MFA SETUP REQUIRED BY USER"
	} ElseIf (!$MFADefault) { #MFA Disabled
		$MFADefault = "N/A"
	}
	$DisplayName=$_.DisplayName
	$Upn=$_.UserPrincipalName
	$Methods=""
	$MethodTypes=$_.StrongAuthenticationMethods.MethodType
	If ($MethodTypes -like ""){$Methods = "-"}
	Else {
		foreach($MethodType in $MethodTypes){
			if($Methods -ne "")
			{
				$Methods=$Methods+","
			}
			$Methods=$Methods+$MethodType
		}
	}
	$email = $_.StrongAuthenticationUserDetails.Email
	$phone = $_.StrongAuthenticationUserDetails.PhoneNumber
	#Export results to Output file
	$Result=@{'DisplayName'=$DisplayName;'UserPrincipalName'=$upn;'MFATypes'=$Methods;'Email'=$email;'Phone'=$phone;'Per-UserMFAStatus'=$MFAStatus;'DefaultMethod'=$MFADefault;'isLicensed'=$_.isLicensed;'BlockCredential'=$_.BlockCredential}
	$Results= New-Object PSObject -Property $Result
	$Results | Select-Object DisplayName,UserPrincipalName,MFATypes,Email,Phone,Per-UserMFAStatus,DefaultMethod,isLicensed,BlockCredential | Export-Csv -Path $ExportCSV -Notype -Append
}
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
Get-PSSession | Remove-PSSession
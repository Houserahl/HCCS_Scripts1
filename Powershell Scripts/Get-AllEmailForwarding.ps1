# Get-AllEmailForwarding

#Check for Microsoft Graph module
$Modules=Get-Module -Name ExchangeOnlineManagement -ListAvailable
if($Modules.count -eq 0)
{
  Write-Host  Please install the Microsoft Exchange Online PowerShell module using the below command: `nInstall-Module ExchangeOnlineManagement -Scope CurrentUser -ForegroundColor yellow
  Exit
}
#Connect to Microsoft Exchange Online
Connect-ExchangeOnline | Out-Null

#Name of Output file
$ExportCSV=".\AllEmailForwarding_$((Get-Date -format yyyy-MMM-dd` HH-mm).ToString()).csv"

#Get all mailbox forwarding
$mailboxes = Get-Mailbox -ResultSize unlimited
$forwarding = $mailboxes | ?{$_.ForwardingAddress -or $_.ForwardingSmtpAddress} | Select DisplayName, WindowsEmailAddress, Forwarding*

ForEach ($forward in $forwarding){
    If ($forward.ForwardingAddress -and $forward.ForwardingSmtpAddress){
        $forwardValue = $forward.ForwardingAddress + $forward.ForwardingSmtpAddress
    } ElseIf ($forward.ForwardingAddress){$forwardValue = $forward.ForwardingAddress}
    Else {$forwardValue = $forward.ForwardingSmtpAddress}
    $Result = @{'DisplayName'=$forward.DisplayName;'Email'=$forward.WindowsEmailAddress;'Enabled'=$TRUE;'ForwardingAddress'=$forwardValue}
    $Results= New-Object PSObject -Property $Result
    $Results | Select-Object DisplayName,Email,Enabled,ForwardingAddress | Export-Csv -Path $ExportCSV -Notype -Append
}

$inboxRules = foreach($mailbox in $mailboxes){
    $tmpRule = Get-InboxRule -Mailbox $mailbox.alias | ?{$_.ForwardAsAttachmentTo -or $_.ForwardTo} | select Identity,Enabled,ForwardTo,ForwardAsAttachmentTo
    If ($tmpRule){
        $forwardValue = ""
        $tmpRule | forEach{
            If ($_.ForwardAsAttachmentTo){$forwardValue += $_.ForwardAsAttachmentTo}
            If ($_.ForwardTo){$forwardValue += $_.ForwardTo}
        }
        $isEnabled = ""
        If ($tmpRule.count -eq 1){
            $isEnabled = $tmpRule.Enabled
        }
        If ($tmpRule.count -gt 1){
            $isEnabled = "Multiple Rules"
        }
        $Result=@{'DisplayName'=$mailbox.DisplayName;'Email'=$WindowsEmailAddress;'Enabled'=$isEnabled;'ForwardingAddress'=$forwardValue}
        $Results= New-Object PSObject -Property $Result
        $Results | Select-Object DisplayName,Email,Enabled,ForwardingAddress | Export-Csv -Path $ExportCSV -Notype -Append
    }
}
# This is the main magic.
Get-Module -ListAvailable VM* | Import-Module

# Dot source the PowerCLI init script

if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
. 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1'
}
Get-Module -ListAvailable VM* | Import-Module
			
$MailtoAddresses= "Alert.vCenter@domainname.com"
$MailSender = "$env:computername@alerts.domainname.com"

#----Connect to the vCenter Server
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Write-Output "**********************"
Write-Output "********FQDN Example: ACME-SA-VCSA.roadrunner.com **************"
$vCenterServer = Read-Host -Prompt 'Input your VCSA or vCenter FQDN or press enter for localhost'
if($vCenterServer -eq ""){
	$vCenterServer = "localhost"
}
Connect-VIServer -Server $vCenterServer -Protocol https -WarningAction SilentlyContinue | Out-Null
Write-Output "*** If there are errors shown above this line hit crtl-c to stop the script and resolve ***"
PAUSE
$sessionManager = Get-View -Id $global:DefaultVIServer.ExtensionData.Content.SessionManager
$sessionManager.SetLocale("en-US")

"Adjusting Datastore Usage Setup"
$predefined = "Datastore usage on disk"  
  
$serviceInstance = get-view ServiceInstance  
  
$alarmMgr = get-view $serviceInstance.Content.alarmManager  
  
$alarms = $alarmMgr.GetAlarm($null)  
$alarms | % {  
	 $alarm = Get-View -Id $_  
	
	 if($predefined -contains $alarm.Info.Name){  
			$alarm.Info.Name
			$spec = New-Object VMware.Vim.AlarmSpec  
		  
			$spec.Action =  $alarm.Info.action
			$spec.Name = $alarm.Info.Name  
			$spec.Description = $alarm.Info.Description  
			$spec.Expression = $alarm.Info.Expression  
			$spec.Enabled = $alarm.Info.Enabled   
			$spec.Setting = $alarm.Info.Setting  
		  

		  

			# Expression 2 - Disk usage
			$expression2 = New-Object VMware.Vim.MetricAlarmExpression
			$expression2.Metric = New-Object VMware.Vim.PerfMetricId
			$expression2.Metric.CounterId = $spec.expression.expression.Metric.CounterId
			$expression2.Metric.Instance = ""
			$expression2.Operator = "isAbove"
			$expression2.Red = 9500
			$expression2.Yellow = 9000
			$expression2.Type = "Datastore"
			$spec.expression = New-Object VMware.Vim.OrAlarmExpression
			$spec.expression.expression = $expression2
 
			$alarm.ReconfigureAlarm($spec)  
	 }  
}  





#Set email sending settings
"Overwriting email settings in vCenter"
Get-AdvancedSetting -Entity $vCenterServer -Name mail.sender | Set-AdvancedSetting -Value $MailSender -Confirm:$false
Get-AdvancedSetting -Entity $vCenterServer -Name mail.smtp.server | Set-AdvancedSetting -Value "alerts.domainname.com" -Confirm:$false
Get-AdvancedSetting -Entity $vCenterServer -Name mail.smtp.port | Set-AdvancedSetting -Value 25000 -Confirm:$false

#----These Alarms will send a single email message and not repeat ----
$LowPriorityAlarms="Timed out starting Secondary VM",`
"No compatible host for Secondary VM",`
"Virtual Machine Fault Tolerance vLockStep interval Status Changed",`
"Migration error",`
"Exit standby error",`
"License error",`
"Virtual machine Fault Tolerance state changed",`
"VMKernel NIC not configured correctly",`
"Unmanaged workload detected on SIOC-enabled datastore",`
"Host IPMI System Event Log status",`
"Host Baseboard Management Controller status",`
"License user threshold monitoring",`
"Datastore capability alarm",`
"Storage DRS recommendation",`
"Storage DRS is not supported on Host.",`
"Datastore is in multiple datacenters",`
"Insufficient vSphere HA failover resources",`
"License capacity monitoring",`
"Pre-4.1 host connected to SIOC-enabled datastore",`
"Virtual machine cpu usage",`
"Virtual machine memory usage",`
"License inventory monitoring"

#----These Alarms will repeat every 24 hours----
$MediumPriorityAlarms=`
"Virtual machine error",`
"Health status changed alarm",`
"Host cpu usage",`
"Health status monitoring",`
"Host memory usage",`
"Cannot find vSphere HA master agent",`
"vSphere HA host status",`
"Host service console swap rates",`
"vSphere HA virtual machine monitoring action",`
"vSphere HA virtual machine monitoring error"


#----These Alarms will repeat every 2 hours----
$HighPriorityAlarms=`
"Host connection and power state",`
"Host processor status",`
"Host memory status",`
"Host hardware fan status",`
"Host hardware voltage",`
"Host hardware temperature status",`
"Host hardware power status",`
"Host hardware system board status",`
"Host battery status",`
"Status of other host hardware objects",`
"Host storage status",`
"Host error",`
"Host connection failure",`
"Cannot connect to storage",`
"Network connectivity lost",`
"Network uplink redundancy lost",`
"Network uplink redundancy degraded",`
"Thin-provisioned volume capacity threshold exceeded.",`
"Datastore cluster is out of space",`
"vSphere HA failover in progress",`
"vSphere HA virtual machine failover failed",`
"Datastore usage on disk"

#---Set Alarm Action for Low Priority Alarms---
Foreach ($LowPriorityAlarm in $LowPriorityAlarms) {
	Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
   Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false
	Get-AlarmDefinition -Name "$LowPriorityAlarm" | New-AlarmAction -Email -To @($MailtoAddresses)
	Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
	#Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red"  # This ActionTrigger is enabled by default.
	Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
	Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}

#---Set Alarm Action for Medium Priority Alarms---
Foreach ($MediumPriorityAlarm in $MediumPriorityAlarms) {
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
	Set-AlarmDefinition "$MediumPriorityAlarm" -ActionRepeatMinutes (60 * 24) # 24 Hours
	Get-AlarmDefinition -Name "$MediumPriorityAlarmm" | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | New-AlarmAction -Email -To @($MailtoAddresses)
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}

#---Set Alarm Action for High Priority Alarms---
Foreach ($HighPriorityAlarm in $HighPriorityAlarms) {
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
	Set-AlarmDefinition "$HighPriorityAlarm" -ActionRepeatMinutes (60 * 2) # 2 hours
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | New-AlarmAction -Email -To @($MailtoAddresses)
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
"******************************************************************************"
"******* disabling vSan - Errors are normal if this has been ran before********"
cmd /c "sc config vsan-health start= disabled"
cmd /c "sc stop vsan-health"
"******************************************************************************"
" "
" "
$vCenterSettings = Get-View -Id 'OptionManager-VpxSettings'
$MailSender = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.sender"}).Value
$MailSmtpServer = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.smtp.server"}).Value
$MailSmtpPort = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.smtp.port"}).Value
$Report = Get-VM | Sort-Object -Property Name | Out-String

Write-Output "Sending vCenter Test Email"
Send-MailMessage -from $MailSender -to $MailtoAddresses -subject "vCenter Test vSphere Report" -body $Report -smtpServer $MailSmtpServer -Port $MailSmtpPort

#---Disconnect from vCenter Server----
Disconnect-VIServer -Server $vCenterServer -Force:$true -Confirm:$false
		
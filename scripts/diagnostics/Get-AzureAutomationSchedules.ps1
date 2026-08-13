<#
.SYNOPSIS
Lists schedules in an Azure Automation Account.

.DESCRIPTION
Read-only helper for troubleshooting scheduled runbooks and confirming expected operational
schedules without changing them.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AutomationAccountName
)

Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName |
    Select-Object Name, StartTime, ExpiryTime, Interval, Frequency, TimeZone, IsEnabled |
    Sort-Object Name | Format-Table -AutoSize

Write-Host 'No Automation schedules were modified.'

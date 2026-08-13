<#
.SYNOPSIS
Inventories Azure Automation Accounts for operational reviews.

.DESCRIPTION
Read-only helper for locating Automation Accounts and confirming identity/region context before
investigating runbooks, schedules or managed identity permissions.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$accounts = if ($ResourceGroupName) { Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName } else { Get-AzAutomationAccount }
$accounts | Select-Object AutomationAccountName, ResourceGroupName, Location, State, Identity |
    Sort-Object ResourceGroupName, AutomationAccountName | Format-Table -AutoSize

Write-Host 'No Automation Account configuration was modified.'

<#
.SYNOPSIS
Lists recent Azure Automation jobs for troubleshooting.

.DESCRIPTION
Read-only helper for reviewing recent runbook execution status, failures and timestamps.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AutomationAccountName
)

Get-AzAutomationJob -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName |
    Sort-Object CreationTime -Descending |
    Select-Object -First 50 JobId, RunbookName, Status, CreationTime, StartTime, EndTime, Exception |
    Format-Table -AutoSize

Write-Host 'No Automation jobs or runbooks were modified.'

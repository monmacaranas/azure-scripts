<#
.SYNOPSIS
Lists Azure Automation runbooks and publication state.

.DESCRIPTION
Read-only helper for locating operational runbooks during troubleshooting and handover.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AutomationAccountName
)

Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName |
    Select-Object Name, RunbookType, State, LastModifiedTime, LogVerbose, LogProgress |
    Sort-Object Name | Format-Table -AutoSize

Write-Host 'No Automation runbooks were modified.'

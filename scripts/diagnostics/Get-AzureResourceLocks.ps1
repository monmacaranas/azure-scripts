<#
.SYNOPSIS
Displays Azure resource locks in the current subscription or specified resource group.

.DESCRIPTION
Read-only helper for troubleshooting failed delete/update operations caused by CanNotDelete
or ReadOnly resource locks.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$ErrorActionPreference = 'Stop'
$locks = if ($ResourceGroupName) {
    Get-AzResourceLock -ResourceGroupName $ResourceGroupName
} else {
    Get-AzResourceLock
}

$locks | Select-Object Name, LockLevel, Notes, ResourceGroupName, ResourceName, ResourceType |
    Sort-Object ResourceGroupName, ResourceName |
    Format-Table -AutoSize

Write-Host 'No resource locks were modified.'

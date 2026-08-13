<#
.SYNOPSIS
Inventories Azure resource tags for operational and ownership reviews.

.DESCRIPTION
Read-only helper used during handover, cleanup, cost attribution and troubleshooting to
confirm resource ownership/environment tags.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$resources = if ($ResourceGroupName) { Get-AzResource -ResourceGroupName $ResourceGroupName } else { Get-AzResource }

$resources | Select-Object Name, ResourceType, ResourceGroupName,
    @{n='Tags';e={($_.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '}} |
    Sort-Object ResourceGroupName, ResourceType, Name |
    Format-Table -AutoSize

Write-Host 'No tags or resources were modified.'

<#
.SYNOPSIS
Displays managed identity information for an Azure resource.

.DESCRIPTION
Read-only helper for troubleshooting managed identity and RBAC issues. Shows identity type,
principal IDs and user-assigned identity references for the selected Azure resource.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ResourceId)

$ErrorActionPreference = 'Stop'
$resource = Get-AzResource -ResourceId $ResourceId -ExpandProperties
$resource.Identity | Format-List

Write-Host 'No identity configuration was modified.'

<#
.SYNOPSIS
Creates a quick read-only Azure subscription resource snapshot for troubleshooting.

.DESCRIPTION
Collects the active subscription context and summarizes resources by type, location and
resource group. Useful at the start of an unfamiliar incident, handover review or inventory
exercise before running service-specific diagnostics.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.Resources. Reader access is normally sufficient.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$ErrorActionPreference = 'Stop'
$ctx = Get-AzContext
if (-not $ctx) { throw 'No Azure context. Run Connect-AzAccount first.' }

Write-Host '=== Azure context ==='
[pscustomobject]@{
    SubscriptionName = $ctx.Subscription.Name
    SubscriptionId   = $ctx.Subscription.Id
    TenantId         = $ctx.Tenant.Id
    Account          = $ctx.Account.Id
} | Format-List

$resources = if ($ResourceGroupName) {
    Get-AzResource -ResourceGroupName $ResourceGroupName
} else {
    Get-AzResource
}

Write-Host "`n=== Resource count ==="
Write-Host $resources.Count

Write-Host "`n=== Resources by type ==="
$resources | Group-Object ResourceType | Sort-Object Count -Descending |
    Select-Object Count, Name | Format-Table -AutoSize

Write-Host "`n=== Resources by location ==="
$resources | Group-Object Location | Sort-Object Count -Descending |
    Select-Object Count, Name | Format-Table -AutoSize

Write-Host "`n=== Resources ==="
$resources | Select-Object Name, ResourceType, ResourceGroupName, Location, ResourceId |
    Sort-Object ResourceGroupName, ResourceType, Name | Format-Table -AutoSize

<#
.SYNOPSIS
Provides Azure subscription context and guidance for exporting cost data.

.DESCRIPTION
Read-only helper used as a safe starting point for Azure cost reviews. It intentionally does
not create budgets, exports or schedules; use Cost Management exports or approved automation
for production reporting.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param()

$ctx = Get-AzContext
if (-not $ctx) { throw 'No Azure context. Run Connect-AzAccount first.' }

[pscustomobject]@{
    SubscriptionName = $ctx.Subscription.Name
    SubscriptionId   = $ctx.Subscription.Id
    TenantId         = $ctx.Tenant.Id
} | Format-List

Write-Host 'Use Azure Cost Management exports/Cost Analysis for authoritative cost data.'
Write-Host 'No budgets, exports or cost settings were modified.'

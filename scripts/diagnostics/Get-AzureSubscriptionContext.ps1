<#
.SYNOPSIS
Shows the active Azure subscription, tenant and signed-in account context.

.DESCRIPTION
Read-only helper for troubleshooting mistakes caused by running commands against the wrong
subscription or tenant.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param()

$ctx = Get-AzContext
if (-not $ctx) { throw 'No Azure context. Run Connect-AzAccount first.' }

[pscustomobject]@{
    Account          = $ctx.Account.Id
    SubscriptionName = $ctx.Subscription.Name
    SubscriptionId   = $ctx.Subscription.Id
    TenantId         = $ctx.Tenant.Id
    Environment      = $ctx.Environment.Name
} | Format-List

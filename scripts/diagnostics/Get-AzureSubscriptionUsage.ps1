<#
.SYNOPSIS
Displays Azure subscription usage/quotas where supported by Az modules.

.DESCRIPTION
Read-only helper for quota and capacity troubleshooting. Intended as a starting point when
resource deployment or scaling fails due to regional/subscription limits.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$Location)

$ErrorActionPreference = 'Continue'
$ctx = Get-AzContext
if (-not $ctx) { throw 'No Azure context. Run Connect-AzAccount first.' }

Write-Host "Subscription: $($ctx.Subscription.Name) ($($ctx.Subscription.Id))"
if ($Location) {
    try {
        Get-AzVMUsage -Location $Location |
            Select-Object @{n='Name';e={$_.Name.LocalizedValue}}, CurrentValue, Limit, Unit |
            Sort-Object Name |
            Format-Table -AutoSize
    } catch { Write-Warning "Unable to read VM usage: $($_.Exception.Message)" }
} else {
    Write-Host 'Specify -Location (for example australiaeast) to show regional VM quota usage.'
}

Write-Host 'No subscription quotas were modified.'

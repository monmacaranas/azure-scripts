<#
.SYNOPSIS
Inventories Azure Policy assignments at the current subscription scope.

.DESCRIPTION
Read-only helper for governance troubleshooting, Defender investigations and reviewing
unexpected policy changes or deletions.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ctx = Get-AzContext
if (-not $ctx) { throw 'No Azure context. Run Connect-AzAccount first.' }
$scope = "/subscriptions/$($ctx.Subscription.Id)"

Get-AzPolicyAssignment -Scope $scope |
    Select-Object Name, DisplayName, Scope, PolicyDefinitionId, EnforcementMode, Identity |
    Sort-Object DisplayName |
    Format-Table -AutoSize

Write-Host 'No policy assignments were modified.'

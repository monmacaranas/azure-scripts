<#
.SYNOPSIS
Inventories high-privilege Azure RBAC assignments for security/access reviews.

.DESCRIPTION
Read-only script used to identify permanent high-impact role assignments such as Owner,
Contributor and User Access Administrator. Useful for privileged-access reviews and for
building a candidate list for Microsoft Entra PIM governance.

SAFETY: READ-ONLY. No role assignments are created, removed or changed.

.REQUIREMENTS
Az.Accounts and Az.Resources. The operator must be able to read role assignments at the
selected scope.

.PARAMETER Scope
Optional Azure scope. Defaults to the current subscription.

.EXAMPLE
./Get-AzurePrivilegedRoleInventory.ps1

.EXAMPLE
./Get-AzurePrivilegedRoleInventory.ps1 -Scope '/subscriptions/<subscription-id>/resourceGroups/<rg>'
#>
[CmdletBinding()]
param([string]$Scope)

$ErrorActionPreference = 'Stop'
$ctx = Get-AzContext
if (-not $ctx) { throw 'No Azure context. Run Connect-AzAccount first.' }
if (-not $Scope) { $Scope = "/subscriptions/$($ctx.Subscription.Id)" }

$privilegedRoles = @('Owner','Contributor','User Access Administrator','Role Based Access Control Administrator')

Write-Host "Review scope: $Scope"
$assignments = Get-AzRoleAssignment -Scope $Scope |
    Where-Object { $_.RoleDefinitionName -in $privilegedRoles } |
    Select-Object DisplayName, SignInName, ObjectType, RoleDefinitionName, Scope, ObjectId

$assignments | Sort-Object RoleDefinitionName, DisplayName | Format-Table -AutoSize

Write-Host "`nSummary"
$assignments | Group-Object RoleDefinitionName | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "`nReview these assignments against business need and PIM eligibility. This script does not determine Entra PIM assignment state and makes no changes."

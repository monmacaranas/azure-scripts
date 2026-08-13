<#
.SYNOPSIS
Finds Azure RBAC assignments for a user, group, service principal or managed identity.

.DESCRIPTION
Read-only troubleshooting helper for access-denied incidents and permission reviews. Search
by object ID to see which Azure roles are assigned and at what scopes.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ObjectId)

$ErrorActionPreference = 'Stop'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

$roles = Get-AzRoleAssignment -ObjectId $ObjectId
$roles | Select-Object DisplayName, SignInName, ObjectType, RoleDefinitionName, Scope |
    Sort-Object Scope, RoleDefinitionName |
    Format-Table -AutoSize

Write-Host "`nAssignments found: $($roles.Count)"
Write-Host 'No Azure role assignments were modified.'

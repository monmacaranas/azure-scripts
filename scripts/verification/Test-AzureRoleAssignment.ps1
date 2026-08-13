<#
.SYNOPSIS
Verifies that a specific Azure RBAC role assignment exists at a scope.

.DESCRIPTION
Read-only post-change check after granting access to a user, group, service principal or
managed identity.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ObjectId,
    [Parameter(Mandatory)][string]$RoleDefinitionName,
    [Parameter(Mandatory)][string]$Scope
)

$ErrorActionPreference = 'Stop'
$assignment = Get-AzRoleAssignment -ObjectId $ObjectId -Scope $Scope |
    Where-Object RoleDefinitionName -eq $RoleDefinitionName

if ($assignment) {
    Write-Host 'PASS: role assignment found.'
    $assignment | Select-Object DisplayName, ObjectType, RoleDefinitionName, Scope | Format-List
} else {
    Write-Warning "FAIL: '$RoleDefinitionName' was not found for object '$ObjectId' at scope '$Scope'."
}

Write-Host 'No Azure role assignments were modified.'

<#
.SYNOPSIS
Reviews Azure role assignments for users, groups, service principals and managed identities.

.DESCRIPTION
Use this read-only script for access reviews, privileged-access investigations, Defender remediation work, and identifying permanent Owner/Contributor or other elevated role assignments that may be candidates for PIM.

.REQUIREMENTS
Az.Accounts, Az.Resources
#>

param(
    [string]$SubscriptionId,
    [string[]]$PrivilegedRoles = @(
        'Owner',
        'Contributor',
        'User Access Administrator',
        'Role Based Access Control Administrator'
    ),
    [string]$OutputPath = ".\azure-rbac-review-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$assignments = Get-AzRoleAssignment | Select-Object `
    DisplayName, SignInName, ObjectType, RoleDefinitionName, Scope, ObjectId

$assignments |
    Sort-Object RoleDefinitionName, DisplayName |
    Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "All role assignments exported to $OutputPath"
Write-Host "`nPrivileged role assignments:"

$assignments |
    Where-Object { $_.RoleDefinitionName -in $PrivilegedRoles } |
    Sort-Object RoleDefinitionName, DisplayName |
    Format-Table -AutoSize

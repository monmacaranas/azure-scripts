<#
.SYNOPSIS
Creates a read-only report of Azure RBAC assignments with emphasis on privileged roles.

.DESCRIPTION
Use this script for access reviews such as permanent Owner/Contributor access, PIM
candidate identification, least-privilege reviews, and evidence collection for Jira or
security remediation work.

By default it highlights Owner, Contributor, User Access Administrator, and Role Based
Access Control Administrator assignments. It does not change RBAC or PIM configuration.

.EXAMPLE
.\Get-AzureRoleAssignmentsReport.ps1 -Scope /subscriptions/<subscription-id>

.EXAMPLE
.\Get-AzureRoleAssignmentsReport.ps1 -Scope /subscriptions/<subscription-id>/resourceGroups/<rg> -OutputPath .\rbac.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Scope,
    [string[]]$PrivilegedRoles = @(
        'Owner',
        'Contributor',
        'User Access Administrator',
        'Role Based Access Control Administrator'
    ),
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$assignments = Get-AzRoleAssignment -Scope $Scope -IncludeClassicAdministrators

$rows = $assignments | ForEach-Object {
    [pscustomobject]@{
        Scope                = $_.Scope
        DisplayName          = $_.DisplayName
        SignInName           = $_.SignInName
        ObjectType           = $_.ObjectType
        ObjectId             = $_.ObjectId
        RoleDefinitionName   = $_.RoleDefinitionName
        RoleAssignmentId     = $_.RoleAssignmentId
        IsPrivilegedRole     = $PrivilegedRoles -contains $_.RoleDefinitionName
        CanReviewForPIM      = ($PrivilegedRoles -contains $_.RoleDefinitionName) -and ($_.ObjectType -in @('User','Group'))
    }
}

Write-Host "`n=== PRIVILEGED / HIGH-IMPACT ASSIGNMENTS ===" -ForegroundColor Cyan
$rows | Where-Object IsPrivilegedRole | Sort-Object RoleDefinitionName, DisplayName | Format-Table -AutoSize -Wrap

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
$rows | Group-Object RoleDefinitionName | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize

if ($OutputPath) {
    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved RBAC report to $OutputPath" -ForegroundColor Green
}

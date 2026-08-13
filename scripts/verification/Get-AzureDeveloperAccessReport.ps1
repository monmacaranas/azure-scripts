<#
.SYNOPSIS
Inventories Azure RBAC access for a developer team across one or more scopes.

.DESCRIPTION
Use this script to collect developer-team access permissions across Corp, Prod, or other
Azure scopes for periodic access review, least-privilege assessment, and security evidence.

Provide developer object IDs explicitly. This avoids relying on display-name matching and
makes the report suitable for repeatable reviews.

The script is read-only and does not change permissions.

.EXAMPLE
.\Get-AzureDeveloperAccessReport.ps1 -Scopes @('/subscriptions/<corp-sub>','/subscriptions/<prod-sub>') -DeveloperObjectIds @('<object-id-1>','<object-id-2>') -OutputPath .\developer-access.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Scopes,
    [Parameter(Mandatory)][string[]]$DeveloperObjectIds,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$rows = [System.Collections.Generic.List[object]]::new()

foreach ($scope in $Scopes) {
    Write-Host "Scanning $scope ..." -ForegroundColor Cyan
    $assignments = Get-AzRoleAssignment -Scope $scope

    foreach ($assignment in $assignments) {
        if ($DeveloperObjectIds -contains $assignment.ObjectId) {
            $rows.Add([pscustomobject]@{
                ReviewedScope       = $scope
                AssignmentScope     = $assignment.Scope
                DisplayName         = $assignment.DisplayName
                SignInName          = $assignment.SignInName
                ObjectType          = $assignment.ObjectType
                ObjectId            = $assignment.ObjectId
                RoleDefinitionName  = $assignment.RoleDefinitionName
                RoleAssignmentId    = $assignment.RoleAssignmentId
                HighPrivilege       = $assignment.RoleDefinitionName -in @(
                    'Owner',
                    'Contributor',
                    'User Access Administrator',
                    'Role Based Access Control Administrator'
                )
            })
        }
    }
}

$rows | Sort-Object ReviewedScope, DisplayName, RoleDefinitionName | Format-Table -AutoSize -Wrap

if ($OutputPath) {
    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved developer access report to $OutputPath" -ForegroundColor Green
}

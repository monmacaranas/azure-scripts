<#
.SYNOPSIS
Grants an Automation Account managed identity the roles required by the SQL VA runbook.

.DESCRIPTION
One-time setup for the companion SQL Vulnerability Assessment automation. This script makes
RBAC changes and should be reviewed before execution.

.PARAMETER AutomationAccountResourceGroup
Resource group containing the Automation Account.

.PARAMETER AutomationAccountName
Automation Account whose system-assigned managed identity needs access.

.PARAMETER SqlResourceGroup
Resource group containing the target SQL logical server.

.PARAMETER SqlServerName
Target SQL logical server name.

.EXAMPLE
.\Grant-SqlVaRunbookPermissions.ps1 `
  -AutomationAccountResourceGroup '<automation-rg>' `
  -AutomationAccountName '<automation-account>' `
  -SqlResourceGroup '<sql-rg>' `
  -SqlServerName '<sql-server>'

.NOTES
SAFETY: MODIFIES AZURE RBAC. No credentials or environment-specific identifiers are stored.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AutomationAccountResourceGroup,
    [Parameter(Mandatory)][string]$AutomationAccountName,
    [Parameter(Mandatory)][string]$SqlResourceGroup,
    [Parameter(Mandatory)][string]$SqlServerName
)

$identityObjectId = (Get-AzAutomationAccount -ResourceGroupName $AutomationAccountResourceGroup `
    -Name $AutomationAccountName).Identity.PrincipalId

if (-not $identityObjectId) {
    throw "Automation Account '$AutomationAccountName' has no system-assigned managed identity enabled."
}

$serverId = (Get-AzSqlServer -ResourceGroupName $SqlResourceGroup -ServerName $SqlServerName).ResourceId

Write-Output "Granting required roles to the Automation Account managed identity."
New-AzRoleAssignment -ObjectId $identityObjectId -RoleDefinitionName 'Reader' -Scope $serverId
New-AzRoleAssignment -ObjectId $identityObjectId -RoleDefinitionName 'SQL Security Manager' -Scope $serverId
Write-Output 'Done. Allow time for RBAC propagation before testing the runbook.'

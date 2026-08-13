<#
.SYNOPSIS
    Grants the Automation Account's system-assigned managed identity the two roles
    Invoke-SqlVaBaselineAcceptance.ps1 needs on a target SQL server/instance.

.DESCRIPTION
    Per Microsoft's documented prerequisites for the unified SQL Vulnerability Assessment API:
      - Reader              -> to list databases via ARM
      - SQL Security Manager -> to read/manage VA settings and baselines

.PARAMETER AutomationAccountResourceGroup
    Resource group containing the Automation Account.

.PARAMETER AutomationAccountName
    Name of the Automation Account whose managed identity needs the roles.

.PARAMETER SqlResourceGroup
    Resource group containing the target SQL logical server.

.PARAMETER SqlServerName
    Name of the target SQL logical server / Managed Instance.

.EXAMPLE
    ./Grant-SqlVaRunbookPermissions.ps1 -AutomationAccountResourceGroup RG-SYSADMIN `
        -AutomationAccountName SysAdminAutomationAccount `
        -SqlResourceGroup RG-DEV-ST-BT -SqlServerName sql-paas-aea-safetrac-test
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $AutomationAccountResourceGroup,
    [Parameter(Mandatory)] [string] $AutomationAccountName,
    [Parameter(Mandatory)] [string] $SqlResourceGroup,
    [Parameter(Mandatory)] [string] $SqlServerName
)

$identityObjectId = (Get-AzAutomationAccount -ResourceGroupName $AutomationAccountResourceGroup `
    -Name $AutomationAccountName).Identity.PrincipalId

if (-not $identityObjectId) {
    throw "Automation Account '$AutomationAccountName' has no system-assigned managed identity enabled. Enable it first (Automation Account -> Identity -> System assigned -> On)."
}

$serverId = (Get-AzSqlServer -ResourceGroupName $SqlResourceGroup -ServerName $SqlServerName).ResourceId

Write-Output "Granting roles to identity $identityObjectId on $serverId"

New-AzRoleAssignment -ObjectId $identityObjectId -RoleDefinitionName "Reader" -Scope $serverId
New-AzRoleAssignment -ObjectId $identityObjectId -RoleDefinitionName "SQL Security Manager" -Scope $serverId

Write-Output "Done. Allow a few minutes for the role assignments to replicate before testing the runbook."

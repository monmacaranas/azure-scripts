<#
.SYNOPSIS
Verifies Azure SQL Database configured maximum size after remediation.

.DESCRIPTION
Read-only post-change check for incidents where a database reached its size quota. Use after
resizing the database or changing the elastic-pool configuration to confirm the effective
capacity settings.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.Sql.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ServerName,
    [Parameter(Mandatory)][string]$DatabaseName
)

$ErrorActionPreference = 'Stop'
$db = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

[pscustomobject]@{
    Database          = $db.DatabaseName
    Status            = $db.Status
    Edition           = $db.Edition
    ServiceObjective  = $db.CurrentServiceObjectiveName
    MaxSizeGB         = [math]::Round($db.MaxSizeBytes / 1GB, 2)
    ElasticPool       = $db.ElasticPoolName
} | Format-List

Write-Host 'Verification complete. No Azure resources were modified.'

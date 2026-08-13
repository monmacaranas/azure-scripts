<#
.SYNOPSIS
Collects Azure SQL Database capacity configuration for size-quota troubleshooting.

.DESCRIPTION
Read-only diagnostic used when applications, ADF pipelines or users report errors such as
"database has reached its size quota". Shows edition/service objective, configured maximum
size and elastic-pool association so the engineer can decide whether to scale, clean up data,
or investigate pool capacity.

SAFETY: READ-ONLY. Does not resize databases or pools.

.REQUIREMENTS
Az.Accounts and Az.Sql with permission to read SQL resources.

.EXAMPLE
./Get-AzureSqlDatabaseCapacity.ps1 -ResourceGroupName '<rg>' -ServerName '<server>' -DatabaseName '<database>'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ServerName,
    [Parameter(Mandatory)][string]$DatabaseName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

$db = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
$db | Select-Object DatabaseName, Status, Edition, CurrentServiceObjectiveName,
    RequestedServiceObjectiveName, MaxSizeBytes, ElasticPoolName, ZoneRedundant,
    ReadScale | Format-List

[pscustomobject]@{
    Database       = $db.DatabaseName
    MaxSizeGB      = [math]::Round($db.MaxSizeBytes / 1GB, 2)
    ServiceTier    = $db.Edition
    ServiceObjective = $db.CurrentServiceObjectiveName
    ElasticPool    = $db.ElasticPoolName
} | Format-Table -AutoSize

if ($db.ElasticPoolName) {
    Write-Host "`n=== Elastic pool ==="
    Get-AzSqlElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ElasticPoolName $db.ElasticPoolName |
        Select-Object ElasticPoolName, Edition, Dtu, StorageMB, DatabaseDtuMin, DatabaseDtuMax, State |
        Format-List
}

Write-Host "`nNext: compare configured maximum capacity with actual database usage/metrics before changing service tier or max size."

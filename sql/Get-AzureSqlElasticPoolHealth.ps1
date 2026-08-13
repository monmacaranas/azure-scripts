<#
.SYNOPSIS
Checks Azure SQL elastic pool configuration and databases.

.DESCRIPTION
Use this read-only script for SQL elastic pool capacity reviews, storage-pressure incidents, DTU/vCore investigations, and before deciding whether to scale a production elastic pool.

.REQUIREMENTS
Az.Accounts, Az.Sql
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ServerName,

    [Parameter(Mandatory)]
    [string]$ElasticPoolName
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$pool = Get-AzSqlElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ElasticPoolName $ElasticPoolName
$databases = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName |
    Where-Object { $_.ElasticPoolName -eq $ElasticPoolName }

Write-Host "=== Elastic Pool ==="
$pool | Select-Object ElasticPoolName, Edition, Dtu, DatabaseDtuMin, DatabaseDtuMax, StorageMB, ZoneRedundant | Format-List

Write-Host "`n=== Databases in pool ==="
$databases |
    Select-Object DatabaseName, Status, Edition, CurrentServiceObjectiveName, MaxSizeBytes |
    Format-Table -AutoSize

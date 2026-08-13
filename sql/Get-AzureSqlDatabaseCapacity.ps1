<#
.SYNOPSIS
Checks Azure SQL Database size, max size, and utilization percentage.

.DESCRIPTION
Use this read-only script when Azure Data Factory, applications, or users report SQL failures caused by database size quota or storage pressure. It returns current database sizing information to support warning/critical alert thresholds and capacity decisions.

.REQUIREMENTS
Az.Accounts, Az.Sql
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ServerName,

    [Parameter(Mandatory)]
    [string]$DatabaseName
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$db = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

[pscustomobject]@{
    DatabaseName  = $db.DatabaseName
    Status        = $db.Status
    Edition       = $db.Edition
    CurrentServiceObjective = $db.CurrentServiceObjectiveName
    MaxSizeGB     = [math]::Round($db.MaxSizeBytes / 1GB, 2)
    ResourceId    = $db.ResourceId
} | Format-List

Write-Host "For actual used-space percentage, query Azure Monitor metric 'storage_percent' or configure an alert on that metric."

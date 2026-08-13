<#
.SYNOPSIS
Reports Azure SQL Database size, configured maximum size, and utilization percentage.

.DESCRIPTION
Use this when troubleshooting Azure Data Factory, application, or ETL failures caused by
"database has reached its size quota" errors. The script is read-only and inventories the
selected database so the operator can decide whether to scale storage, clean up data, or
review indexes before making a production change.

It is useful for incident evidence collection and for deciding warning/critical alert
thresholds.

.REQUIREMENTS
Az.Accounts and Az.Sql PowerShell modules.

.EXAMPLE
.\Get-AzureSqlDatabaseCapacity.ps1 -ResourceGroupName rg-data -ServerName sql-prod -DatabaseName appdb
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ServerName,
    [Parameter(Mandatory)][string]$DatabaseName
)

$ErrorActionPreference = 'Stop'

if (-not (Get-AzContext)) {
    Connect-AzAccount | Out-Null
}

$db = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

$usedBytes = $null
try {
    $metric = Get-AzMetric -ResourceId $db.ResourceId -MetricName 'storage' -TimeGrain 00:05:00 -StartTime (Get-Date).AddHours(-1) -EndTime (Get-Date)
    $usedBytes = ($metric.Data | Where-Object Average | Select-Object -Last 1).Average
}
catch {
    Write-Warning "Unable to retrieve storage metric: $($_.Exception.Message)"
}

$maxBytes = [double]$db.MaxSizeBytes
$usedGB = if ($usedBytes) { [math]::Round($usedBytes / 1GB, 2) } else { $null }
$maxGB = [math]::Round($maxBytes / 1GB, 2)
$percent = if ($usedBytes -and $maxBytes -gt 0) { [math]::Round(($usedBytes / $maxBytes) * 100, 2) } else { $null }

[pscustomobject]@{
    ResourceGroup       = $ResourceGroupName
    Server              = $ServerName
    Database            = $DatabaseName
    Edition             = $db.Edition
    CurrentServiceLevel = $db.CurrentServiceObjectiveName
    MaxSizeGB           = $maxGB
    UsedStorageGB       = $usedGB
    UsedPercent         = $percent
    Status              = $db.Status
    ResourceId          = $db.ResourceId
}

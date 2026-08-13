<#
.SYNOPSIS
Reports Azure SQL Database short-term and long-term backup retention configuration.

.DESCRIPTION
Use this script for backup-retention audits, Azure Automation validation, compliance checks,
and troubleshooting situations where SQL retention settings may not match the intended
policy. It queries each database on an Azure SQL logical server and reports short-term
retention plus available long-term retention policy details.

The script is read-only.

.EXAMPLE
.\Get-AzureSqlRetentionStatus.ps1 -ResourceGroupName ASE-RSG-PRD-APP -ServerName sql-paas-ase-safetrac-prd

.EXAMPLE
.\Get-AzureSqlRetentionStatus.ps1 -ResourceGroupName rg-sql -ServerName sql-prod -OutputPath .\sql-retention.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ServerName,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$databases = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName |
    Where-Object DatabaseName -ne 'master'

$rows = foreach ($db in $databases) {
    $str = $null
    $ltr = $null

    try {
        $str = Get-AzSqlDatabaseBackupShortTermRetentionPolicy `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName `
            -DatabaseName $db.DatabaseName `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to read STR for $($db.DatabaseName): $($_.Exception.Message)"
    }

    try {
        $ltr = Get-AzSqlDatabaseBackupLongTermRetentionPolicy `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName `
            -DatabaseName $db.DatabaseName `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to read LTR for $($db.DatabaseName): $($_.Exception.Message)"
    }

    [pscustomobject]@{
        ServerName             = $ServerName
        DatabaseName           = $db.DatabaseName
        Edition                = $db.Edition
        Status                 = $db.Status
        STRRetentionDays       = $str.RetentionDays
        STRDiffBackupHours     = $str.DiffBackupIntervalInHours
        LTRWeeklyRetention     = $ltr.WeeklyRetention
        LTRMonthlyRetention    = $ltr.MonthlyRetention
        LTRYearlyRetention     = $ltr.YearlyRetention
        LTRWeekOfYear          = $ltr.WeekOfYear
    }
}

$rows | Format-Table -AutoSize

if ($OutputPath) {
    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved SQL retention report to $OutputPath" -ForegroundColor Green
}

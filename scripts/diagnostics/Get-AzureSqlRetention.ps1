<#
.SYNOPSIS
Displays Azure SQL Database short-term and long-term backup retention settings.

.DESCRIPTION
Read-only helper for retention audits and troubleshooting backup-retention automation.
Useful for confirming the effective PITR and LTR configuration before or after runbook work.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.Sql.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ServerName,
    [string]$DatabaseName
)

$ErrorActionPreference = 'Stop'
$dbs = if ($DatabaseName) {
    @(Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName)
} else {
    Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName |
        Where-Object DatabaseName -ne 'master'
}

foreach ($db in $dbs) {
    Write-Host "`n=== $($db.DatabaseName) ==="
    try {
        Get-AzSqlDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName -DatabaseName $db.DatabaseName |
            Format-List
    } catch { Write-Warning "STR: $($_.Exception.Message)" }

    try {
        Get-AzSqlDatabaseBackupLongTermRetentionPolicy -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName -DatabaseName $db.DatabaseName |
            Format-List
    } catch { Write-Warning "LTR: $($_.Exception.Message)" }
}

Write-Host 'No retention settings were modified.'

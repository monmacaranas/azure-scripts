<#
.SYNOPSIS
Inventories Azure Monitor diagnostic settings for a resource.

.DESCRIPTION
Read-only troubleshooting script used to confirm whether platform/resource logs and metrics
are being sent to Log Analytics, Storage or Event Hub. Useful before building alerts or when
expected telemetry is missing.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.Monitor.

.PARAMETER ResourceId
Full Azure resource ID.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ResourceId)

$ErrorActionPreference = 'Stop'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

Write-Host "=== Supported categories ==="
Get-AzDiagnosticSettingCategory -ResourceId $ResourceId |
    Select-Object Name, CategoryType |
    Sort-Object CategoryType, Name |
    Format-Table -AutoSize

Write-Host "`n=== Configured diagnostic settings ==="
$settings = Get-AzDiagnosticSetting -ResourceId $ResourceId
if (-not $settings) {
    Write-Warning 'No diagnostic settings are configured for this resource.'
    return
}

foreach ($setting in $settings) {
    Write-Host "`n--- $($setting.Name) ---"
    $setting | Select-Object Name, WorkspaceId, StorageAccountId,
        EventHubAuthorizationRuleId, EventHubName | Format-List

    if ($setting.Log) {
        Write-Host 'Logs:'
        $setting.Log | Select-Object Category, CategoryGroup, Enabled | Format-Table -AutoSize
    }
    if ($setting.Metric) {
        Write-Host 'Metrics:'
        $setting.Metric | Select-Object Category, Enabled | Format-Table -AutoSize
    }
}

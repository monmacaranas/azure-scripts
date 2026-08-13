<#
.SYNOPSIS
Retrieves recent Azure Activity Log operations for troubleshooting and change review.

.DESCRIPTION
Read-only helper for identifying recent administrative changes, failed operations and the
caller/correlation ID involved in an incident.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [int]$Hours = 24,
    [string]$ResourceGroupName
)

$ErrorActionPreference = 'Stop'
$start = (Get-Date).AddHours(-$Hours)
$params = @{ StartTime = $start }
if ($ResourceGroupName) { $params.ResourceGroupName = $ResourceGroupName }

Get-AzActivityLog @params |
    Select-Object EventTimestamp, OperationName, Status, Caller, ResourceGroupName,
        ResourceId, CorrelationId |
    Sort-Object EventTimestamp -Descending |
    Format-Table -AutoSize

Write-Host 'No Azure resources were modified.'

<#
.SYNOPSIS
Collects Microsoft Defender for Cloud security recommendations for a selected subscription.

.DESCRIPTION
Read-only inventory used during Azure security reviews to identify unhealthy Defender for
Cloud assessments and correlate affected Azure resources with remediation work.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.SecurityInsights/Az.Security-compatible Defender cmdlets available in the
operator environment. If Get-AzSecurityAssessment is unavailable, use Azure Resource Graph
or Defender for Cloud portal export instead.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }
if (-not (Get-Command Get-AzSecurityAssessment -ErrorAction SilentlyContinue)) {
    throw 'Get-AzSecurityAssessment is not available in this PowerShell environment. Install/update the appropriate Az security module.'
}

$findings = Get-AzSecurityAssessment |
    Where-Object { $_.Status.Code -eq 'Unhealthy' } |
    Select-Object DisplayName, ResourceDetailsResourceId, Status, AdditionalData

Write-Host '=== Unhealthy Defender for Cloud assessments ==='
$findings | Sort-Object DisplayName | Format-Table DisplayName, ResourceDetailsResourceId -AutoSize

Write-Host "`nTotal unhealthy assessments: $($findings.Count)"
Write-Host 'No security settings or findings were modified.'

<#
.SYNOPSIS
Exports active Microsoft Defender for Cloud / Azure Security recommendations.

.DESCRIPTION
Use this script during security reviews, developer-access assessments, remediation planning,
and Jira evidence collection. It queries Azure Resource Graph for current security
recommendations and can optionally restrict results to resource IDs containing a supplied
text filter.

The script is read-only.

.REQUIREMENTS
- Az.Accounts
- Az.ResourceGraph
- Reader/Security Reader permissions appropriate to the target subscriptions

.EXAMPLE
.\Get-AzureDefenderFindings.ps1 -SubscriptionIds @('<sub-id-1>','<sub-id-2>') -OutputPath .\defender-findings.csv

.EXAMPLE
.\Get-AzureDefenderFindings.ps1 -SubscriptionIds @('<sub-id>') -ResourceIdContains '/resourceGroups/rg-prod'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$SubscriptionIds,
    [string]$ResourceIdContains,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Az.ResourceGraph)) {
    throw 'Az.ResourceGraph is required. Install-Module Az.ResourceGraph -Scope CurrentUser'
}

$query = @"
securityresources
| where type =~ 'microsoft.security/assessments'
| extend status = tostring(properties.status.code)
| where status !~ 'Healthy'
| extend recommendation = tostring(properties.displayName),
         severity = tostring(properties.metadata.severity),
         resourceId = tostring(properties.resourceDetails.Id),
         remediation = tostring(properties.metadata.remediationDescription),
         assessmentKey = name
| project subscriptionId, resourceGroup, resourceId, recommendation, severity, status, remediation, assessmentKey
"@

$results = Search-AzGraph -Query $query -Subscription $SubscriptionIds -First 5000

if ($ResourceIdContains) {
    $results = $results | Where-Object { $_.resourceId -like "*$ResourceIdContains*" }
}

$results = $results | Sort-Object severity, recommendation, resourceId

Write-Host "`n=== DEFENDER FOR CLOUD ACTIVE FINDINGS ===" -ForegroundColor Cyan
$results | Format-Table subscriptionId, resourceGroup, severity, status, recommendation, resourceId -AutoSize -Wrap

Write-Host "`n=== SUMMARY BY SEVERITY ===" -ForegroundColor Cyan
$results | Group-Object severity | Select-Object Count, Name | Format-Table -AutoSize

if ($OutputPath) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved Defender findings to $OutputPath" -ForegroundColor Green
}

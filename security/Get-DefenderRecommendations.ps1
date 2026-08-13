<#
.SYNOPSIS
Finds Microsoft Defender for Cloud recommendations affecting Azure resources.

.DESCRIPTION
Use this read-only script for Defender remediation, developer access reviews, security task reporting, and determining which Azure resources have active Defender for Cloud recommendations. Results can be filtered or correlated with RBAC exports to prioritize exposed resources.

.REQUIREMENTS
Az.Accounts, Az.Security
#>

param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\defender-recommendations-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$tasks = Get-AzSecurityTask -ErrorAction SilentlyContinue

$results = foreach ($task in $tasks) {
    [pscustomobject]@{
        Name       = $task.Name
        State      = $task.State
        ResourceId = $task.ResourceId
        CreationTimeUtc = $task.CreationTimeUtc
        LastStateChangeTimeUtc = $task.LastStateChangeTimeUtc
    }
}

$results | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "Defender for Cloud task/recommendation data exported to $OutputPath"

<#
.SYNOPSIS
Collects Azure subscription and resource context for troubleshooting.

.DESCRIPTION
Use this read-only script at the start of an Azure incident or support task to capture the current account, tenant, subscription, resource groups, and high-level resource inventory. It helps prevent troubleshooting in the wrong subscription and provides evidence that can be attached to Jira or incident records.

.REQUIREMENTS
Az.Accounts, Az.Resources
#>

param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\azure-context-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$context = Get-AzContext
Write-Host "Tenant:       $($context.Tenant.Id)"
Write-Host "Subscription: $($context.Subscription.Name) [$($context.Subscription.Id)]"
Write-Host "Account:      $($context.Account.Id)"

$resources = Get-AzResource | Select-Object Name, ResourceType, ResourceGroupName, Location, ResourceId
$resources | Sort-Object ResourceGroupName, ResourceType, Name | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Resource inventory exported to $OutputPath"

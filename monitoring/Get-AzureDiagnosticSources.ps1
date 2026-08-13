<#
.SYNOPSIS
Discovers diagnostic settings and available log categories for an Azure resource.

.DESCRIPTION
Use this read-only script when designing Azure Monitor alerts or when troubleshooting why expected logs are missing. It shows existing diagnostic settings and the categories that the selected resource can emit to Log Analytics, Storage, or Event Hub.

.EXAMPLE
.\Get-AzureDiagnosticSources.ps1 -ResourceId "/subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/app1"
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceId
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

Write-Host "=== Existing diagnostic settings ==="
Get-AzDiagnosticSetting -ResourceId $ResourceId -ErrorAction SilentlyContinue |
    Select-Object Name, WorkspaceId, StorageAccountId, EventHubAuthorizationRuleId

Write-Host "`n=== Available diagnostic categories ==="
Get-AzDiagnosticSettingCategory -ResourceId $ResourceId |
    Select-Object Name, CategoryType

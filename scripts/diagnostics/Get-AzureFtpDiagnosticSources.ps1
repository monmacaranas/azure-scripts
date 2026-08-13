<#
.SYNOPSIS
Discovers Azure diagnostic and logging sources useful when investigating FTP/FTPS connections.

.DESCRIPTION
Read-only troubleshooting script intended for incidents and alert-design work where the first
question is: "What telemetry is actually available for this Azure resource?" It inventories
diagnostic settings, supported diagnostic categories and App Service logging configuration.

Typical use cases:
- Determine whether FTP/FTPS connection activity can be observed for an App Service.
- Identify Log Analytics workspaces already receiving resource logs.
- Gather evidence before designing an Azure Monitor alert or KQL query.
- Troubleshoot missing production FTP connection telemetry.

SAFETY: READ-ONLY. This script does not create or change Azure resources.

.REQUIREMENTS
Az.Accounts, Az.Resources, Az.Monitor, Az.Websites. Reader access is normally sufficient.

.PARAMETER ResourceId
Full Azure resource ID of the resource being investigated.

.EXAMPLE
./Get-AzureFtpDiagnosticSources.ps1 -ResourceId '/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<app>'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceId
)

$ErrorActionPreference = 'Stop'

if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

Write-Host "`n=== Resource ==="
$resource = Get-AzResource -ResourceId $ResourceId
$resource | Select-Object Name, ResourceType, ResourceGroupName, Location, ResourceId | Format-List

Write-Host "`n=== Existing diagnostic settings ==="
try {
    $settings = Get-AzDiagnosticSetting -ResourceId $ResourceId
    if ($settings) {
        $settings | Select-Object Name, WorkspaceId, StorageAccountId, EventHubAuthorizationRuleId, EventHubName | Format-List
    } else { Write-Warning 'No diagnostic settings found.' }
} catch { Write-Warning "Unable to read diagnostic settings: $($_.Exception.Message)" }

Write-Host "`n=== Supported diagnostic categories ==="
try {
    Get-AzDiagnosticSettingCategory -ResourceId $ResourceId |
        Select-Object Name, CategoryType |
        Sort-Object CategoryType, Name |
        Format-Table -AutoSize
} catch { Write-Warning "Unable to enumerate diagnostic categories: $($_.Exception.Message)" }

if ($resource.ResourceType -eq 'Microsoft.Web/sites') {
    Write-Host "`n=== App Service configuration relevant to FTP/FTPS ==="
    try {
        $app = Get-AzWebApp -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
        $app.SiteConfig | Select-Object FtpsState, HttpLoggingEnabled, DetailedErrorLoggingEnabled, RequestTracingEnabled | Format-List
    } catch { Write-Warning "Unable to read App Service configuration: $($_.Exception.Message)" }

    Write-Host "`nInvestigation note: correlate available App Service/resource logs with Azure Activity Log and authentication/network telemetry before choosing an alert signal."
}

Write-Host "`nCompleted. No Azure resources were modified."

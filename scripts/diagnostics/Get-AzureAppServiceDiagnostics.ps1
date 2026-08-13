<#
.SYNOPSIS
Collects common Azure App Service configuration for troubleshooting.

.DESCRIPTION
Read-only evidence collection for App Service incidents involving networking, identity,
TLS/FTPS configuration, VNet integration and missing diagnostic telemetry.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts, Az.Websites and Az.Monitor.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$Name
)

$ErrorActionPreference = 'Continue'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction Stop

Write-Host '=== App Service ==='
$app | Select-Object Name, State, Location, DefaultHostName, HttpsOnly, OutboundIpAddresses,
    PossibleOutboundIpAddresses | Format-List

Write-Host "`n=== Identity ==="
$app.Identity | Format-List

Write-Host "`n=== Site configuration ==="
$app.SiteConfig | Select-Object FtpsState, MinTlsVersion, Http20Enabled, AlwaysOn,
    VnetRouteAllEnabled, PublicNetworkAccess, HttpLoggingEnabled,
    DetailedErrorLoggingEnabled, RequestTracingEnabled | Format-List

Write-Host "`n=== VNet integration ==="
try {
    Get-AzWebAppVNetConnection -ResourceGroupName $ResourceGroupName -WebAppName $Name |
        Format-List
} catch {
    Write-Warning "Unable to read VNet integration: $($_.Exception.Message)"
}

Write-Host "`n=== Diagnostic settings ==="
try {
    Get-AzDiagnosticSetting -ResourceId $app.Id |
        Select-Object Name, WorkspaceId, StorageAccountId, EventHubName |
        Format-List
} catch {
    Write-Warning "Unable to read diagnostic settings: $($_.Exception.Message)"
}

Write-Host "`nCompleted. No Azure resources were modified."

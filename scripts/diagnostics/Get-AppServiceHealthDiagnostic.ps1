<#
.SYNOPSIS
Collects read-only Azure App Service health and configuration information.

.DESCRIPTION
Use this script when an App Service is unhealthy, unreachable, failing to access Azure
resources, or suspected of having VNet integration, outbound IP, TLS, or plan-capacity
problems. It collects the common first-response configuration without changing the app.

.REQUIREMENTS
- Azure PowerShell Az module
- Reader access

.EXAMPLE
.\Get-AppServiceHealthDiagnostic.ps1 -ResourceGroupName rg-app -WebAppName myapp
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$WebAppName,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
$plan = Get-AzAppServicePlan -ResourceGroupName $app.ResourceGroup -Name ($app.ServerFarmId.Split('/')[-1])

$report = [ordered]@{
    Timestamp                = (Get-Date).ToString('s')
    Name                     = $app.Name
    State                    = $app.State
    Location                 = $app.Location
    DefaultHostName          = $app.DefaultHostName
    HttpsOnly                = $app.HttpsOnly
    ClientCertEnabled        = $app.ClientCertEnabled
    OutboundIpAddresses      = $app.OutboundIpAddresses
    PossibleOutboundIPs      = $app.PossibleOutboundIpAddresses
    VirtualNetworkSubnetId   = $app.VirtualNetworkSubnetId
    PublicNetworkAccess      = $app.PublicNetworkAccess
    AppServicePlan           = $plan.Name
    PlanSku                  = $plan.Sku
    NumberOfWorkers          = $plan.NumberOfWorkers
    MaximumNumberOfWorkers   = $plan.MaximumNumberOfWorkers
}

Write-Host "`n=== APP SERVICE HEALTH / CONFIGURATION ===" -ForegroundColor Cyan
[pscustomobject]$report | Format-List

Write-Host "`n=== APP SETTINGS (names only where sensitive) ===" -ForegroundColor Cyan
try {
    $settings = Get-AzWebAppApplicationSetting -ResourceGroupName $ResourceGroupName -Name $WebAppName
    $settings.Properties.PSObject.Properties.Name | Sort-Object
}
catch {
    Write-Warning "Unable to read app setting names: $($_.Exception.Message)"
}

Write-Host "`n=== CONNECTION STRINGS (names/types only) ===" -ForegroundColor Cyan
try {
    $app.SiteConfig.ConnectionStrings | Select-Object Name, Type | Format-Table -AutoSize
}
catch {
    Write-Warning "Unable to inspect connection string metadata: $($_.Exception.Message)"
}

if ($OutputPath) {
    [pscustomobject]$report | ConvertTo-Json -Depth 8 | Out-File $OutputPath -Encoding utf8
    Write-Host "Saved report to $OutputPath" -ForegroundColor Green
}

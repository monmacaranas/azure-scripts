<#
.SYNOPSIS
Collects read-only Azure Application Gateway troubleshooting information.

.DESCRIPTION
Use this script during Application Gateway incidents, migrations, backend-health problems,
TLS/certificate issues, listener/routing failures, or V1-to-V2 validation. It collects the
configuration that is most commonly required before changing a gateway: SKU, frontend IPs,
listeners, backend pools, HTTP settings, probes, routing rules, SSL certificates, subnet,
and backend health.

The script is read-only and makes no changes.

.REQUIREMENTS
- Azure PowerShell Az module
- Connect-AzAccount completed
- Reader access to the Application Gateway and related networking resources

.EXAMPLE
.\Get-AppGatewayDiagnostic.ps1 -ResourceGroupName MSS_IFS_PROD_WE -ApplicationGatewayName AGWEAZUIFS100
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ApplicationGatewayName,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Az.Network)) {
    throw 'Az.Network is required. Install-Module Az -Scope CurrentUser'
}

$gw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName

$result = [ordered]@{
    Timestamp          = (Get-Date).ToString('s')
    Name               = $gw.Name
    ResourceGroup      = $ResourceGroupName
    Location           = $gw.Location
    OperationalState   = $gw.OperationalState
    ProvisioningState  = $gw.ProvisioningState
    Sku                = $gw.Sku
    GatewayIPConfig    = $gw.GatewayIPConfigurations
    FrontendIPs        = $gw.FrontendIPConfigurations
    FrontendPorts      = $gw.FrontendPorts
    BackendPools       = $gw.BackendAddressPools
    HttpSettings       = $gw.BackendHttpSettingsCollection
    Probes             = $gw.Probes
    Listeners          = $gw.HttpListeners
    RoutingRules       = $gw.RequestRoutingRules
    RedirectConfigs    = $gw.RedirectConfigurations
    RewriteRuleSets    = $gw.RewriteRuleSets
    SslCertificates    = $gw.SslCertificates | Select-Object Name, ProvisioningState, PublicCertData
}

Write-Host "`n=== APPLICATION GATEWAY SUMMARY ===" -ForegroundColor Cyan
$result | Format-List

Write-Host "`n=== BACKEND HEALTH ===" -ForegroundColor Cyan
try {
    $health = Get-AzApplicationGatewayBackendHealth -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName
    $health.BackendAddressPools | ForEach-Object {
        Write-Host "Pool: $($_.BackendAddressPool.Id)"
        $_.BackendHttpSettingsCollection | ForEach-Object {
            Write-Host "  HTTP Setting: $($_.BackendHttpSettings.Id)"
            $_.Servers | Select-Object Address, Health, HealthProbeLog | Format-Table -AutoSize
        }
    }
}
catch {
    Write-Warning "Backend health could not be retrieved: $($_.Exception.Message)"
}

if ($OutputPath) {
    $result | ConvertTo-Json -Depth 12 | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Saved configuration evidence to $OutputPath" -ForegroundColor Green
}

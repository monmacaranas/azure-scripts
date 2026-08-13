<#
.SYNOPSIS
Collects read-only Azure Application Gateway troubleshooting information.

.DESCRIPTION
Use during Application Gateway incidents, migrations, backend-health problems, TLS/certificate
issues, listener/routing failures or V1-to-V2 validation. It collects common configuration
and backend-health evidence before any change is made.

SAFETY: READ-ONLY.

.EXAMPLE
.\Get-AppGatewayDiagnostic.ps1 -ResourceGroupName '<resource-group>' -ApplicationGatewayName '<application-gateway>'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ApplicationGatewayName,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Az.Network)) { throw 'Az.Network is required.' }

$gw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName
$result = [ordered]@{
    Timestamp         = (Get-Date).ToString('s')
    Name              = $gw.Name
    ResourceGroup     = $ResourceGroupName
    Location          = $gw.Location
    OperationalState  = $gw.OperationalState
    ProvisioningState = $gw.ProvisioningState
    Sku               = $gw.Sku
    GatewayIPConfig   = $gw.GatewayIPConfigurations
    FrontendIPs       = $gw.FrontendIPConfigurations
    FrontendPorts     = $gw.FrontendPorts
    BackendPools      = $gw.BackendAddressPools
    HttpSettings      = $gw.BackendHttpSettingsCollection
    Probes            = $gw.Probes
    Listeners         = $gw.HttpListeners
    RoutingRules      = $gw.RequestRoutingRules
    RedirectConfigs   = $gw.RedirectConfigurations
    RewriteRuleSets   = $gw.RewriteRuleSets
    SslCertificates   = $gw.SslCertificates | Select-Object Name, ProvisioningState
}

$result | Format-List
try {
    $health = Get-AzApplicationGatewayBackendHealth -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName
    $health.BackendAddressPools | ForEach-Object {
        $_.BackendHttpSettingsCollection | ForEach-Object {
            $_.Servers | Select-Object Address, Health, HealthProbeLog | Format-Table -AutoSize
        }
    }
} catch { Write-Warning "Backend health could not be retrieved: $($_.Exception.Message)" }

if ($OutputPath) { $result | ConvertTo-Json -Depth 12 | Out-File -FilePath $OutputPath -Encoding utf8 }

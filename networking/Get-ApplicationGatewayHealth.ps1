<#
.SYNOPSIS
Checks Azure Application Gateway backend health and key configuration.

.DESCRIPTION
Use this read-only script when troubleshooting Application Gateway incidents, backend connectivity, listener/rule configuration, health probe failures, or V1-to-V2 migration validation for applications such as IFS.

.REQUIREMENTS
Az.Accounts, Az.Network
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ApplicationGatewayName
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$gw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName

Write-Host "=== Application Gateway ==="
$gw | Select-Object Name, Location, OperationalState, Sku, GatewayIPConfigurations, FrontendIPConfigurations | Format-List

Write-Host "`n=== Backend Health ==="
Get-AzApplicationGatewayBackendHealth -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName |
    ConvertTo-Json -Depth 8

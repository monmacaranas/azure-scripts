<#
.SYNOPSIS
Collects Azure Application Gateway configuration for troubleshooting.

.DESCRIPTION
Read-only helper for incidents involving listeners, frontend IPs, backend pools, HTTP
settings, health probes and SSL configuration.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$Name
)

$ErrorActionPreference = 'Stop'
$agw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $Name

Write-Host '=== Gateway ==='
$agw | Select-Object Name, Location, OperationalState, ProvisioningState, Sku,
    FrontendIPConfigurations, FrontendPorts | Format-List

Write-Host "`n=== Backend pools ==="
$agw.BackendAddressPools | Select-Object Name, BackendAddresses | Format-List

Write-Host "`n=== HTTP settings ==="
$agw.BackendHttpSettingsCollection | Select-Object Name, Port, Protocol, HostName,
    PickHostNameFromBackendAddress, RequestTimeout, Probe | Format-Table -AutoSize

Write-Host "`n=== Probes ==="
$agw.Probes | Select-Object Name, Protocol, Host, Path, Interval, Timeout,
    UnhealthyThreshold | Format-Table -AutoSize

Write-Host 'No Application Gateway configuration was modified.'

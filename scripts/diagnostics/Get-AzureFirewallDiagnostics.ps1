<#
.SYNOPSIS
Collects Azure Firewall configuration and attached IP configurations.

.DESCRIPTION
Read-only helper for connectivity incidents where Azure Firewall may be in the traffic path.
Shows firewall SKU, threat-intel mode, provisioning state and IP configuration references.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$FirewallName
)

$ErrorActionPreference = 'Stop'
$fw = Get-AzFirewall -ResourceGroupName $ResourceGroupName -Name $FirewallName
$fw | Select-Object Name, Location, ProvisioningState, ThreatIntelMode, Sku, IpConfigurations,
    ManagementIpConfiguration, FirewallPolicy | Format-List

Write-Host 'No firewall configuration was modified.'

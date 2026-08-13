<#
.SYNOPSIS
Lists Azure VNet peerings for troubleshooting connectivity.

.DESCRIPTION
Read-only helper to review peering state, address forwarding and gateway settings before
changing network configuration.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$VirtualNetworkName
)

Get-AzVirtualNetworkPeering -ResourceGroupName $ResourceGroupName -VirtualNetworkName $VirtualNetworkName |
    Select-Object Name, PeeringState, RemoteVirtualNetwork, AllowVirtualNetworkAccess,
        AllowForwardedTraffic, AllowGatewayTransit, UseRemoteGateways |
    Format-Table -AutoSize

Write-Host 'No VNet peerings were modified.'

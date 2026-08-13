<#
.SYNOPSIS
Checks Azure VNet peering configuration and connectivity state.

.DESCRIPTION
Use this read-only script when troubleshooting cross-VNet connectivity such as AVD-to-production access, application-to-database paths, hub/spoke routing, or incidents caused by missing or disconnected peerings.

.REQUIREMENTS
Az.Accounts, Az.Network
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$VirtualNetworkName
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VirtualNetworkName

$vnet.VirtualNetworkPeerings |
    Select-Object Name,
                  PeeringState,
                  PeeringSyncLevel,
                  AllowVirtualNetworkAccess,
                  AllowForwardedTraffic,
                  AllowGatewayTransit,
                  UseRemoteGateways,
                  RemoteVirtualNetwork |
    Format-List

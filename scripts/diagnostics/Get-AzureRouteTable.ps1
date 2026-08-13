<#
.SYNOPSIS
Displays Azure route-table routes for network troubleshooting.

.DESCRIPTION
Read-only helper used when investigating traffic paths, UDRs, Azure Firewall routing,
Private Endpoints, Application Gateway or AVD connectivity.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$RouteTableName
)

$ErrorActionPreference = 'Stop'
$rt = Get-AzRouteTable -ResourceGroupName $ResourceGroupName -Name $RouteTableName

$rt.Routes |
    Sort-Object AddressPrefix |
    Select-Object Name, AddressPrefix, NextHopType, NextHopIpAddress, HasBgpOverride |
    Format-Table -AutoSize

Write-Host 'No routes were modified.'

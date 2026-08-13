<#
.SYNOPSIS
Inventories Azure subnet service endpoints.

.DESCRIPTION
Read-only helper for troubleshooting storage, SQL and other Azure PaaS connectivity where
service endpoints may be part of the design.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$vnets = if ($ResourceGroupName) { Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName } else { Get-AzVirtualNetwork }

foreach ($vnet in $vnets) {
    foreach ($subnet in $vnet.Subnets) {
        foreach ($endpoint in $subnet.ServiceEndpoints) {
            [pscustomobject]@{
                ResourceGroup = $vnet.ResourceGroupName
                VNet          = $vnet.Name
                Subnet        = $subnet.Name
                Service       = $endpoint.Service
                Locations     = $endpoint.Locations -join ', '
            }
        }
    }
} | Sort-Object ResourceGroup, VNet, Subnet, Service | Format-Table -AutoSize

Write-Host 'No service endpoints were modified.'

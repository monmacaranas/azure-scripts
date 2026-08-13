<#
.SYNOPSIS
Inventories Azure subnets, address prefixes, NSGs, route tables and service endpoints.

.DESCRIPTION
Read-only helper for network troubleshooting and environment reviews.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$vnets = if ($ResourceGroupName) { Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName } else { Get-AzVirtualNetwork }

foreach ($vnet in $vnets) {
    foreach ($subnet in $vnet.Subnets) {
        [pscustomobject]@{
            VNet            = $vnet.Name
            ResourceGroup   = $vnet.ResourceGroupName
            Subnet          = $subnet.Name
            AddressPrefixes = $subnet.AddressPrefix -join ', '
            NSG             = if ($subnet.NetworkSecurityGroup) { ($subnet.NetworkSecurityGroup.Id -split '/')[-1] } else { '' }
            RouteTable      = if ($subnet.RouteTable) { ($subnet.RouteTable.Id -split '/')[-1] } else { '' }
            ServiceEndpoints = $subnet.ServiceEndpoints.Service -join ', '
        }
    }
} | Sort-Object ResourceGroup, VNet, Subnet | Format-Table -AutoSize

Write-Host 'No subnet configuration was modified.'

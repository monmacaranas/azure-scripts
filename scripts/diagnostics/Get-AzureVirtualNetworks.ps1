<#
.SYNOPSIS
Inventories Azure virtual networks and address spaces.

.DESCRIPTION
Read-only helper for network troubleshooting, environment handover and confirming VNet/subnet
structure before making changes.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$vnets = if ($ResourceGroupName) {
    Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName
} else {
    Get-AzVirtualNetwork
}

foreach ($vnet in $vnets) {
    [pscustomobject]@{
        Name          = $vnet.Name
        ResourceGroup = $vnet.ResourceGroupName
        Location      = $vnet.Location
        AddressSpaces = $vnet.AddressSpace.AddressPrefixes -join ', '
        Subnets       = $vnet.Subnets.Name -join ', '
    }
} | Sort-Object ResourceGroup, Name | Format-Table -AutoSize

Write-Host 'No virtual networks were modified.'

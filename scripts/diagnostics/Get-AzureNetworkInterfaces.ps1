<#
.SYNOPSIS
Inventories Azure network interfaces for troubleshooting and resource reviews.

.DESCRIPTION
Read-only helper showing NIC resource group, location, attached VM, NSG and IP configuration.
Useful during VM/network incidents and decommissioning reviews.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$nics = if ($ResourceGroupName) {
    Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName
} else {
    Get-AzNetworkInterface
}

$nics | Select-Object Name, ResourceGroupName, Location, VirtualMachine, NetworkSecurityGroup,
    @{n='PrivateIPs';e={$_.IpConfigurations.PrivateIpAddress -join ', '}} |
    Sort-Object ResourceGroupName, Name | Format-Table -AutoSize

Write-Host 'No network interfaces were modified.'

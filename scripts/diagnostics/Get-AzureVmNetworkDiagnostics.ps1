<#
.SYNOPSIS
Collects VM NIC, subnet, NSG and private IP information for Azure network troubleshooting.

.DESCRIPTION
Read-only helper for VM connectivity incidents. Useful when checking whether a VM is on the
expected subnet, which NSG is attached and which private IP/DNS settings are in use.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$VmName
)

$ErrorActionPreference = 'Stop'
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
    $nicName = ($nicRef.Id -split '/')[-1]
    $nicRg = ($nicRef.Id -split '/')[4]
    $nic = Get-AzNetworkInterface -ResourceGroupName $nicRg -Name $nicName

    Write-Host "`n=== NIC: $nicName ==="
    $nic | Select-Object Name, Location, NetworkSecurityGroup, DnsSettings, EnableAcceleratedNetworking |
        Format-List

    $nic.IpConfigurations | Select-Object Name, PrivateIpAddress, PrivateIpAllocationMethod,
        Subnet, PublicIpAddress | Format-List
}

Write-Host 'No VM or network configuration was modified.'

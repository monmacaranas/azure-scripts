<#
.SYNOPSIS
Lists custom DNS server configuration for Azure VNets.

.DESCRIPTION
Read-only helper for DNS troubleshooting, especially Private Endpoint and AVD scenarios where
custom DNS servers or forwarders are in use.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$vnets = if ($ResourceGroupName) {
    Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName
} else {
    Get-AzVirtualNetwork
}

$vnets | Select-Object Name, ResourceGroupName,
    @{n='DnsServers';e={ if ($_.DhcpOptions.DnsServers) { $_.DhcpOptions.DnsServers -join ', ' } else { 'Azure-provided DNS' } }} |
    Sort-Object ResourceGroupName, Name |
    Format-Table -AutoSize

Write-Host 'No DNS settings were modified.'

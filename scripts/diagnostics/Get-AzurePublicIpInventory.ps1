<#
.SYNOPSIS
Inventories Azure Public IP resources in the current subscription or a resource group.

.DESCRIPTION
Read-only helper for external attack surface reviews, firewall allow-list checks and incident
triage involving internet-facing Azure resources.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$ErrorActionPreference = 'Stop'
$ips = if ($ResourceGroupName) {
    Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName
} else {
    Get-AzPublicIpAddress
}

$ips | Select-Object Name, ResourceGroupName, Location, IpAddress, PublicIpAllocationMethod,
    Sku, DnsSettings, IpConfiguration |
    Sort-Object ResourceGroupName, Name |
    Format-Table -AutoSize

Write-Host 'No public IP resources were modified.'

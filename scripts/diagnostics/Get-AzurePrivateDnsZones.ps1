<#
.SYNOPSIS
Inventories Azure Private DNS zones, VNet links and record sets.

.DESCRIPTION
Read-only helper for Private Endpoint and name-resolution troubleshooting. Use to confirm
zone existence, linked VNets and expected A/CNAME records before changing DNS.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$ErrorActionPreference = 'Stop'
$zones = if ($ResourceGroupName) {
    Get-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName
} else {
    Get-AzPrivateDnsZone
}

foreach ($zone in $zones) {
    Write-Host "`n=== $($zone.Name) ==="
    Write-Host 'VNet links:'
    Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name |
        Select-Object Name, RegistrationEnabled, VirtualNetworkId, LinkState |
        Format-Table -AutoSize

    Write-Host 'Record sets:'
    Get-AzPrivateDnsRecordSet -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name |
        Select-Object Name, RecordType, Ttl, Records |
        Format-Table -AutoSize
}

Write-Host 'No DNS records or links were modified.'

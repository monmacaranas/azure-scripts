<#
.SYNOPSIS
Inventories Azure managed disks for troubleshooting and cleanup reviews.

.DESCRIPTION
Read-only helper to identify disk size, SKU, state, encryption and whether a disk is attached.
Useful during VM incidents, cost reviews and decommissioning checks.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$disks = if ($ResourceGroupName) {
    Get-AzDisk -ResourceGroupName $ResourceGroupName
} else {
    Get-AzDisk
}

$disks | Select-Object Name, ResourceGroupName, Location, DiskSizeGB, Sku, DiskState,
    ManagedBy, Encryption | Sort-Object ResourceGroupName, Name | Format-Table -AutoSize

Write-Host 'No managed disks were modified.'

<#
.SYNOPSIS
Inventories Azure Private Endpoints and connection state.

.DESCRIPTION
Read-only helper for Private Endpoint troubleshooting, showing target resources, approval
state and NIC references.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$pes = if ($ResourceGroupName) { Get-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName } else { Get-AzPrivateEndpoint }

foreach ($pe in $pes) {
    [pscustomobject]@{
        Name          = $pe.Name
        ResourceGroup = $pe.ResourceGroupName
        Location      = $pe.Location
        Subnet        = ($pe.Subnet.Id -split '/')[-1]
        Connections   = ($pe.PrivateLinkServiceConnections.Name -join ', ')
        State         = ($pe.PrivateLinkServiceConnections.PrivateLinkServiceConnectionState.Status -join ', ')
    }
} | Sort-Object ResourceGroup, Name | Format-Table -AutoSize

Write-Host 'No Private Endpoints were modified.'

<#
.SYNOPSIS
Maps Azure Private Endpoints to network interfaces, private IPs and DNS zone groups.

.DESCRIPTION
Read-only diagnostic used when Private Endpoint DNS resolution is unclear or when engineers
need to confirm which private IP belongs to which Azure service connection.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.Network.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$ErrorActionPreference = 'Continue'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

$pes = if ($ResourceGroupName) {
    Get-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName
} else {
    Get-AzPrivateEndpoint
}

foreach ($pe in $pes) {
    Write-Host "`n=== Private Endpoint: $($pe.Name) ==="
    $pe | Select-Object Name, Location, Subnet, PrivateLinkServiceConnections,
        ManualPrivateLinkServiceConnections | Format-List

    foreach ($nicRef in $pe.NetworkInterfaces) {
        try {
            $nicName = ($nicRef.Id -split '/')[-1]
            $nicRg = ($nicRef.Id -split '/')[4]
            Get-AzNetworkInterface -ResourceGroupName $nicRg -Name $nicName |
                Select-Object Name, @{n='PrivateIPs';e={$_.IpConfigurations.PrivateIpAddress -join ', '}} |
                Format-Table -AutoSize
        } catch { Write-Warning $_.Exception.Message }
    }

    try {
        Get-AzPrivateDnsZoneGroup -ResourceGroupName $pe.ResourceGroupName -PrivateEndpointName $pe.Name |
            Select-Object Name, PrivateDnsZoneConfigs | Format-List
    } catch {
        Write-Warning 'No Private DNS zone group found or it could not be read.'
    }
}

Write-Host "`nCompleted. No Azure resources were modified."

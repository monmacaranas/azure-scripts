<#
.SYNOPSIS
Reports Azure Private DNS zones, VNet links, and record sets.

.DESCRIPTION
Use this script when troubleshooting Private Endpoint name resolution, missing VNet links,
incorrect private IP records, custom DNS forwarding, or split-horizon DNS behavior.
It is read-only and useful for incident evidence and architecture reviews.

.EXAMPLE
.\Get-PrivateDnsZoneReport.ps1 -ResourceGroupName rg-network

.EXAMPLE
.\Get-PrivateDnsZoneReport.ps1 -ResourceGroupName rg-network -ZoneName privatelink.blob.core.windows.net
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [string]$ZoneName,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$zones = if ($ZoneName) {
    @(Get-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName)
} else {
    @(Get-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName)
}

$rows = foreach ($zone in $zones) {
    $links = @(Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $ResourceGroupName -ZoneName $zone.Name -ErrorAction SilentlyContinue)
    $records = @(Get-AzPrivateDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $zone.Name -ErrorAction SilentlyContinue)

    [pscustomobject]@{
        ZoneName             = $zone.Name
        ResourceGroup        = $ResourceGroupName
        NumberOfRecordSets   = $zone.NumberOfRecordSets
        MaxNumberOfRecordSets= $zone.MaxNumberOfRecordSets
        VNetLinks            = ($links | ForEach-Object { "$($_.Name) -> $($_.VirtualNetworkId) [Registration=$($_.RegistrationEnabled)]" }) -join '; '
        ARecords             = ($records | Where-Object RecordType -eq 'A' | ForEach-Object { "$($_.Name)=$((($_.Records | ForEach-Object Ipv4Address) -join ','))" }) -join '; '
    }
}

$rows | Format-Table -AutoSize -Wrap

if ($OutputPath) {
    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved Private DNS report to $OutputPath" -ForegroundColor Green
}

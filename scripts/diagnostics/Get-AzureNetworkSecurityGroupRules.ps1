<#
.SYNOPSIS
Displays Azure Network Security Group rules for troubleshooting connectivity.

.DESCRIPTION
Read-only helper used to review effective NSG configuration before changing firewall or
network rules. Lists custom inbound and outbound rules in priority order.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$NetworkSecurityGroupName
)

$ErrorActionPreference = 'Stop'
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NetworkSecurityGroupName

Write-Host '=== Inbound rules ==='
$nsg.SecurityRules | Where-Object Direction -eq 'Inbound' |
    Sort-Object Priority |
    Select-Object Priority, Name, Access, Protocol, SourceAddressPrefix,
        SourcePortRange, DestinationAddressPrefix, DestinationPortRange |
    Format-Table -AutoSize

Write-Host "`n=== Outbound rules ==="
$nsg.SecurityRules | Where-Object Direction -eq 'Outbound' |
    Sort-Object Priority |
    Select-Object Priority, Name, Access, Protocol, SourceAddressPrefix,
        SourcePortRange, DestinationAddressPrefix, DestinationPortRange |
    Format-Table -AutoSize

Write-Host 'No NSG rules were modified.'

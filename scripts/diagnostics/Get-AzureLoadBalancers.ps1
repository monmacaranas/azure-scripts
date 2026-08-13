<#
.SYNOPSIS
Inventories Azure Load Balancers for troubleshooting.

.DESCRIPTION
Read-only helper showing SKU, frontend IP configuration, backend pools, probes and rules.
Useful during network path investigations and infrastructure handover.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$lbs = if ($ResourceGroupName) {
    Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName
} else {
    Get-AzLoadBalancer
}

foreach ($lb in $lbs) {
    Write-Host "`n=== $($lb.Name) ==="
    $lb | Select-Object Name, Location, Sku, FrontendIpConfigurations,
        BackendAddressPools, Probes, LoadBalancingRules | Format-List
}

Write-Host 'No load balancers were modified.'

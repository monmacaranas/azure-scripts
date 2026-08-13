<#
.SYNOPSIS
Verifies DNS resolution and TCP connectivity for an Azure Private Endpoint-backed service.

.DESCRIPTION
Read-only post-change verification script. It resolves a service FQDN, reports returned IPs,
checks whether they are private addresses and optionally tests a TCP port. Useful after
Private DNS zone links, DNS forwarders, VNet peering or Private Endpoint changes.

SAFETY: READ-ONLY. Runs client-side DNS and TCP tests only.

.PARAMETER HostName
Service hostname to resolve, for example mystorage.blob.core.windows.net.

.PARAMETER Port
TCP port to test. Defaults to 443.

.EXAMPLE
./Test-AzurePrivateEndpointDns.ps1 -HostName '<storage>.blob.core.windows.net'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [int]$Port = 443
)

Write-Host "=== DNS resolution: $HostName ==="
try {
    $dns = Resolve-DnsName -Name $HostName -ErrorAction Stop
    $dns | Select-Object Name, Type, IPAddress, NameHost | Format-Table -AutoSize

    $ips = $dns | Where-Object IPAddress | Select-Object -ExpandProperty IPAddress -Unique
    foreach ($ip in $ips) {
        $private = $ip -match '^10\.' -or $ip -match '^192\.168\.' -or $ip -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.'
        [pscustomobject]@{ IPAddress = $ip; RFC1918Private = $private }
    }
} catch {
    Write-Error "DNS resolution failed: $($_.Exception.Message)"
}

Write-Host "`n=== TCP $Port ==="
Test-NetConnection -ComputerName $HostName -Port $Port |
    Select-Object ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded, InterfaceAlias, SourceAddress |
    Format-List

<#
.SYNOPSIS
    Diagnoses "can't reach the storage account" symptoms from a client machine (dev laptop,
    VPN-connected or not), distinguishing DNS/network problems from application-layer ones.

.DESCRIPTION
    Grew out of troubleshooting three separate Safetrac storage-connectivity tickets, where
    the pattern initially looked like a shared network/firewall block across accounts but
    turned out to be distinct, non-network causes each time (a malformed URL, an expired
    credential, and a stale VPN DNS/connection-pool state). Run this BEFORE assuming a
    network or Private Endpoint problem -- it usually rules the network layer out fast.

    Deliberately avoids plain `nslookup` with no server argument: it queries the local
    router/DNS server directly and can time out under a connected VPN even when the real
    resolver (used by ping, Test-NetConnection, and actual applications) works fine. That
    false signal cost real troubleshooting time once already -- don't repeat it.

.PARAMETER StorageAccountHostname
    Fully-qualified blob endpoint, e.g. saasesafetractest.blob.core.windows.net

.EXAMPLE
    ./Test-StorageConnectivity.ps1 -StorageAccountHostname saasesafetractest.blob.core.windows.net

.NOTES
    Run once with the VPN connected and once without, and compare. If a Private Endpoint is
    configured, expect the resolved IP to differ between the two runs (private IP on VPN,
    public IP off VPN) -- that's expected and healthy, not a fault.
    If everything below succeeds but the application still fails, the cause is very likely
    application-layer (credential, connection string, or a cached connection from before a
    VPN state change) rather than network/firewall -- see the repo README troubleshooting
    notes for the "restart after VPN state change" pattern.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $StorageAccountHostname
)

Write-Output "=== Storage connectivity check: $StorageAccountHostname ==="
Write-Output "Timestamp (local): $(Get-Date)"
Write-Output ""

Write-Output "--- DNS resolution (using the OS resolver, not a direct server query) ---"
try {
    Resolve-DnsName -Name $StorageAccountHostname -ErrorAction Stop | Format-Table Name, IPAddress -AutoSize
} catch {
    Write-Warning "Resolve-DnsName failed: $($_.Exception.Message)"
}

Write-Output "--- Ping (ICMP; some networks block this even when TCP works fine) ---"
try {
    Test-Connection -ComputerName $StorageAccountHostname -Count 2 -ErrorAction Stop |
        Format-Table Address, ResponseTime -AutoSize
} catch {
    Write-Warning "Ping failed or was blocked: $($_.Exception.Message)"
}

Write-Output "--- TCP 443 reachability (the check that actually matters for HTTPS traffic) ---"
try {
    $result = Test-NetConnection -ComputerName $StorageAccountHostname -Port 443 -ErrorAction Stop
    $result | Format-List ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded
} catch {
    Write-Warning "Test-NetConnection failed: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "If TcpTestSucceeded is True, the network path is fine -- look at the application's"
Write-Output "own error (auth failure vs. resource-not-found vs. timeout) rather than the network."

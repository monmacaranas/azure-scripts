<#
.SYNOPSIS
Diagnoses "can't reach the storage account" symptoms from a client machine.

.DESCRIPTION
Use this before assuming a network, firewall or Private Endpoint problem. It checks DNS,
ICMP and TCP 443 using the operating system resolver and helps separate network issues from
application/authentication issues.

SAFETY: READ-ONLY.

.PARAMETER StorageAccountHostname
Fully-qualified storage endpoint, for example <storage-account>.blob.core.windows.net.

.EXAMPLE
.\Test-StorageConnectivity.ps1 -StorageAccountHostname '<storage-account>.blob.core.windows.net'
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$StorageAccountHostname)

Write-Output "=== Storage connectivity check: $StorageAccountHostname ==="
Write-Output "Timestamp (local): $(Get-Date)"
Write-Output ""

Write-Output "--- DNS resolution ---"
try {
    Resolve-DnsName -Name $StorageAccountHostname -ErrorAction Stop |
        Format-Table Name, IPAddress -AutoSize
} catch {
    Write-Warning "Resolve-DnsName failed: $($_.Exception.Message)"
}

Write-Output "--- Ping ---"
try {
    Test-Connection -ComputerName $StorageAccountHostname -Count 2 -ErrorAction Stop |
        Format-Table Address, ResponseTime -AutoSize
} catch {
    Write-Warning "Ping failed or was blocked: $($_.Exception.Message)"
}

Write-Output "--- TCP 443 reachability ---"
try {
    Test-NetConnection -ComputerName $StorageAccountHostname -Port 443 -ErrorAction Stop |
        Format-List ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded
} catch {
    Write-Warning "Test-NetConnection failed: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "If TCP 443 succeeds, investigate application authentication, URL/path and cached connection state next."

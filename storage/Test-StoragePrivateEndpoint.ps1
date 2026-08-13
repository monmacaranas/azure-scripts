<#
.SYNOPSIS
Tests a Storage Account endpoint from the current host.

.DESCRIPTION
Use this during Blob/Files Private Endpoint troubleshooting to compare DNS and TCP behavior while connected and disconnected from VPN. It is especially useful for validating private DNS resolution and confirming HTTPS reachability.

.EXAMPLE
.\Test-StoragePrivateEndpoint.ps1 -StorageAccountName "saasesafetracassetstest"
#>

param(
    [Parameter(Mandatory)]
    [string]$StorageAccountName,

    [ValidateSet('blob','file','dfs','queue','table')]
    [string]$Service = 'blob',

    [int]$Port = 443
)

$hostName = "$StorageAccountName.$Service.core.windows.net"

Write-Host "Testing $hostName"
Write-Host "`n=== NSLOOKUP ==="
nslookup $hostName

Write-Host "`n=== PING ==="
ping $hostName

Write-Host "`n=== TCP ==="
Test-NetConnection -ComputerName $hostName -Port $Port |
    Select-Object ComputerName, RemoteAddress, RemotePort, SourceAddress, InterfaceAlias, TcpTestSucceeded

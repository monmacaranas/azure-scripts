<#
.SYNOPSIS
Tests DNS resolution and TCP connectivity to an Azure/private endpoint.

.DESCRIPTION
Use this during Azure networking incidents to confirm how a hostname resolves, which IP is returned, and whether a required TCP port is reachable from the current host. Useful for App Gateway, Private Endpoint, SQL, Storage, AVD and application connectivity troubleshooting.

.EXAMPLE
.\Test-AzureEndpoint.ps1 -HostName "example.privatelink.blob.core.windows.net" -Ports 443,445
#>

param(
    [Parameter(Mandatory)]
    [string]$HostName,

    [int[]]$Ports = @(443)
)

Write-Host "=== DNS resolution ==="
try {
    Resolve-DnsName -Name $HostName -ErrorAction Stop |
        Select-Object Name, Type, IPAddress, NameHost
}
catch {
    Write-Warning "DNS resolution failed: $($_.Exception.Message)"
}

Write-Host "`n=== TCP connectivity ==="
foreach ($port in $Ports) {
    Test-NetConnection -ComputerName $HostName -Port $port |
        Select-Object ComputerName, RemoteAddress, RemotePort, InterfaceAlias, SourceAddress, TcpTestSucceeded
}

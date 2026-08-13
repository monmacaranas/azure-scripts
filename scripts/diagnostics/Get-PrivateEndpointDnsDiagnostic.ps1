<#
.SYNOPSIS
Collects DNS evidence for an Azure Private Endpoint-backed resource.

.DESCRIPTION
Use this when a client, VM, AVD host, pipeline agent, or application resolves an Azure
service incorrectly or cannot connect after Private Endpoint deployment. The script is
read-only. It compares normal DNS resolution with a specified DNS server and records the
resolved addresses for both the public service FQDN and the privatelink FQDN.

This is useful when troubleshooting Azure Storage, SQL, Key Vault, App Service, or other
Private Link-enabled services before changing Private DNS zones, VNet links, DNS forwarders,
or custom DNS servers.

.EXAMPLE
.\Get-PrivateEndpointDnsDiagnostic.ps1 -HostName mystorage.blob.core.windows.net -PrivateLinkHostName mystorage.privatelink.blob.core.windows.net -DnsServer 10.0.3.4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][string]$PrivateLinkHostName,
    [string]$DnsServer
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Client DNS configuration ==="
Get-DnsClientServerAddress | Format-Table -AutoSize

Write-Host "`n=== Resolve service FQDN ==="
Resolve-DnsName $HostName -ErrorAction Continue | Format-Table -AutoSize

Write-Host "`n=== Resolve privatelink FQDN ==="
Resolve-DnsName $PrivateLinkHostName -ErrorAction Continue | Format-Table -AutoSize

if ($DnsServer) {
    Write-Host "`n=== Resolve service FQDN using $DnsServer ==="
    Resolve-DnsName $HostName -Server $DnsServer -ErrorAction Continue | Format-Table -AutoSize

    Write-Host "`n=== Resolve privatelink FQDN using $DnsServer ==="
    Resolve-DnsName $PrivateLinkHostName -Server $DnsServer -ErrorAction Continue | Format-Table -AutoSize
}

Write-Host "`n=== TCP 443 test ==="
Test-NetConnection -ComputerName $HostName -Port 443 -InformationLevel Detailed

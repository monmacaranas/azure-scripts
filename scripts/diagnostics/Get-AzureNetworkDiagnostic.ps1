<#
.SYNOPSIS
Collects common Windows-side network diagnostics for an Azure-hosted endpoint.

.DESCRIPTION
Use this when troubleshooting DNS failures, Private Endpoint routing, Application Gateway
reachability, storage connectivity or any Azure service that appears unreachable from a
Windows client/server. The script is read-only.

.EXAMPLE
.\Get-AzureNetworkDiagnostic.ps1 -HostName '<hostname>' -Port 443 -HttpsPath '/health'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [int]$Port = 443,
    [string]$HttpsPath,
    [string]$OutputPath = ".\network-diagnostic-$((Get-Date).ToString('yyyyMMdd-HHmmss')).txt"
)

$ErrorActionPreference = 'Continue'
function Write-Section { param([string]$Name) "`n===== $Name =====" | Tee-Object -FilePath $OutputPath -Append }

"Azure Network Diagnostic" | Set-Content $OutputPath
"Timestamp: $(Get-Date -Format o)" | Add-Content $OutputPath
"Computer: $env:COMPUTERNAME" | Add-Content $OutputPath
"Target: $HostName`:$Port" | Add-Content $OutputPath

Write-Section 'DNS resolution'
try { Resolve-DnsName $HostName | Format-Table -AutoSize | Out-String | Tee-Object -FilePath $OutputPath -Append } catch { $_ | Out-String | Tee-Object -FilePath $OutputPath -Append }

Write-Section 'TCP connectivity'
Test-NetConnection -ComputerName $HostName -Port $Port -InformationLevel Detailed | Format-List * | Out-String | Tee-Object -FilePath $OutputPath -Append

Write-Section 'IP configuration'
Get-NetIPConfiguration | Format-List * | Out-String | Tee-Object -FilePath $OutputPath -Append

Write-Section 'DNS client configuration'
Get-DnsClientServerAddress | Format-Table -AutoSize | Out-String | Tee-Object -FilePath $OutputPath -Append

Write-Section 'Route table'
Get-NetRoute -AddressFamily IPv4 | Sort-Object DestinationPrefix, RouteMetric | Format-Table -AutoSize | Out-String | Tee-Object -FilePath $OutputPath -Append

Write-Section 'WinHTTP proxy'
(netsh winhttp show proxy) | Out-String | Tee-Object -FilePath $OutputPath -Append

if ($HttpsPath) {
    Write-Section 'HTTPS request'
    $uri = "https://${HostName}:$Port$HttpsPath"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -Method Get -TimeoutSec 30
        "URI: $uri" | Tee-Object -FilePath $OutputPath -Append
        "StatusCode: $($response.StatusCode)" | Tee-Object -FilePath $OutputPath -Append
    } catch {
        $_ | Format-List * -Force | Out-String | Tee-Object -FilePath $OutputPath -Append
    }
}

Write-Host "Diagnostic complete: $OutputPath"

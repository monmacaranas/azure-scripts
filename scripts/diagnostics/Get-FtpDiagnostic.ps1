<#
.SYNOPSIS
Collects client-side FTP/FTPS connectivity evidence without changing configuration.

.DESCRIPTION
Use this for production FTP incident investigation and alert-design work such as ITP-346.
It checks DNS resolution, TCP connectivity to common FTP ports, local proxy settings, and
optionally tests a specific host/port. The output can be attached to Jira or an incident
record before firewall, NSG, Private Endpoint, App Service, or FTP server changes are made.

This script does not authenticate to the FTP service and does not transmit credentials.

.EXAMPLE
.\Get-FtpDiagnostic.ps1 -HostName ftp.contoso.com -Ports 21,22,990
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [int[]]$Ports = @(21,22,990),
    [string]$OutputPath = ".\ftp-diagnostic-$((Get-Date).ToString('yyyyMMdd-HHmmss')).txt"
)

"FTP/FTPS Diagnostic" | Set-Content $OutputPath
"Timestamp: $(Get-Date -Format o)" | Add-Content $OutputPath
"Computer: $env:COMPUTERNAME" | Add-Content $OutputPath
"Target: $HostName" | Add-Content $OutputPath

"`n===== DNS =====" | Add-Content $OutputPath
try { Resolve-DnsName $HostName | Format-Table -AutoSize | Out-String | Add-Content $OutputPath } catch { $_ | Out-String | Add-Content $OutputPath }

foreach ($port in $Ports) {
    "`n===== TCP $port =====" | Add-Content $OutputPath
    Test-NetConnection -ComputerName $HostName -Port $port -InformationLevel Detailed |
        Format-List * | Out-String | Add-Content $OutputPath
}

"`n===== DNS client =====" | Add-Content $OutputPath
Get-DnsClientServerAddress | Format-Table -AutoSize | Out-String | Add-Content $OutputPath

"`n===== Routes =====" | Add-Content $OutputPath
Get-NetRoute -AddressFamily IPv4 | Sort-Object RouteMetric |
    Format-Table -AutoSize | Out-String | Add-Content $OutputPath

"`n===== WinHTTP proxy =====" | Add-Content $OutputPath
(netsh winhttp show proxy) | Out-String | Add-Content $OutputPath

Write-Host "Diagnostic complete: $OutputPath"

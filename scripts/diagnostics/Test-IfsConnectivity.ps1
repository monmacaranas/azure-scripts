<#
.SYNOPSIS
Performs read-only connectivity checks for an application endpoint behind Azure Application Gateway.

.DESCRIPTION
Use this script for application/ClickOnce connectivity incidents where DNS, Application
Gateway, TLS, proxy or backend reachability is suspected. It gathers repeatable before/after
evidence from a Windows client or server.

The script does not authenticate to the application and does not change configuration.

.EXAMPLE
.\Test-IfsConnectivity.ps1 -HostName '<application-hostname>' -Port 443 -Path '/health'

.EXAMPLE
.\Test-IfsConnectivity.ps1 -HostName '<application-hostname>' -Port 443 -ExpectedIp '<private-ip>' -BackendServers '<backend-1>','<backend-2>'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [int]$Port = 443,
    [string]$Path = '/health',
    [string]$ExpectedIp,
    [string[]]$BackendServers,
    [string]$OutputPath
)

$ErrorActionPreference = 'Continue'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string]$Test,[string]$Target,[string]$Status,[string]$Details)
    $results.Add([pscustomobject]@{Time=(Get-Date).ToString('s');Test=$Test;Target=$Target;Status=$Status;Details=$Details})
}

try {
    $dns = Resolve-DnsName -Name $HostName -ErrorAction Stop
    $ips = ($dns | Where-Object IPAddress | Select-Object -ExpandProperty IPAddress) -join ', '
    Add-Result DNS $HostName PASS $ips
    if ($ExpectedIp) {
        $match = $dns.IPAddress -contains $ExpectedIp
        Add-Result ExpectedIP $ExpectedIp ($(if($match){'PASS'}else{'FAIL'})) "Resolved IPs: $ips"
    }
} catch { Add-Result DNS $HostName FAIL $_.Exception.Message }

try {
    $tcp = Test-NetConnection -ComputerName $HostName -Port $Port -WarningAction SilentlyContinue
    Add-Result TCP "$HostName`:$Port" ($(if($tcp.TcpTestSucceeded){'PASS'}else{'FAIL'})) "RemoteAddress=$($tcp.RemoteAddress); SourceAddress=$($tcp.SourceAddress)"
} catch { Add-Result TCP "$HostName`:$Port" FAIL $_.Exception.Message }

try {
    $uri = "https://$HostName`:$Port$Path"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 30
    Add-Result HTTPS $uri PASS "HTTP $($response.StatusCode)"
} catch { Add-Result HTTPS "https://$HostName`:$Port$Path" FAIL $_.Exception.Message }

if ($BackendServers) {
    foreach ($server in $BackendServers) {
        try {
            $test = Test-NetConnection -ComputerName $server -Port $Port -WarningAction SilentlyContinue
            Add-Result BackendTCP "$server`:$Port" ($(if($test.TcpTestSucceeded){'PASS'}else{'FAIL'})) "RemoteAddress=$($test.RemoteAddress)"
        } catch { Add-Result BackendTCP "$server`:$Port" FAIL $_.Exception.Message }
    }
}

$results | Format-Table -AutoSize -Wrap
if ($OutputPath) { $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8 }

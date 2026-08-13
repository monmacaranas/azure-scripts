<#
.SYNOPSIS
Performs read-only connectivity checks for IFS endpoints behind Azure Application Gateway.

.DESCRIPTION
Use this script for IFS/ClickOnce connectivity incidents where DNS, Application Gateway,
TCP 48080, TLS, proxy, or backend reachability is suspected. It gathers repeatable
before/after evidence from a Windows client or server.

The script does not authenticate to IFS and does not change configuration.

.EXAMPLE
.\Test-IfsConnectivity.ps1 -HostName ifs10.erb.global -Port 48080 -Path /admin

.EXAMPLE
.\Test-IfsConnectivity.ps1 -HostName ifs10.erb.global -Port 48080 -ExpectedIp 10.243.141.10 -BackendServers SERBWEAZUIFS101,SERBWEAZUIFS102,SERBWEAZUIFS103
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$HostName,

    [int]$Port = 48080,

    [string]$Path = '/admin',

    [string]$ExpectedIp,

    [string[]]$BackendServers,

    [string]$OutputPath
)

$ErrorActionPreference = 'Continue'
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string]$Test,[string]$Target,[string]$Status,[string]$Details)
    $results.Add([pscustomobject]@{
        Time    = (Get-Date).ToString('s')
        Test    = $Test
        Target  = $Target
        Status  = $Status
        Details = $Details
    })
}

Write-Host "=== IFS CONNECTIVITY DIAGNOSTIC ===" -ForegroundColor Cyan
Write-Host "Target: https://$HostName`:$Port$Path"

try {
    $dns = Resolve-DnsName -Name $HostName -ErrorAction Stop
    $ips = ($dns | Where-Object IPAddress | Select-Object -ExpandProperty IPAddress) -join ', '
    Add-Result DNS $HostName PASS $ips
    if ($ExpectedIp) {
        $match = $dns.IPAddress -contains $ExpectedIp
        Add-Result ExpectedIP $ExpectedIp ($(if($match){'PASS'}else{'FAIL'})) "Resolved IPs: $ips"
    }
}
catch {
    Add-Result DNS $HostName FAIL $_.Exception.Message
}

try {
    $tcp = Test-NetConnection -ComputerName $HostName -Port $Port -WarningAction SilentlyContinue
    Add-Result TCP "$HostName`:$Port" ($(if($tcp.TcpTestSucceeded){'PASS'}else{'FAIL'})) "RemoteAddress=$($tcp.RemoteAddress); SourceAddress=$($tcp.SourceAddress); Interface=$($tcp.InterfaceAlias)"
}
catch {
    Add-Result TCP "$HostName`:$Port" FAIL $_.Exception.Message
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://$HostName`:$Port$Path"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 30
    Add-Result HTTPS $uri PASS "HTTP $($response.StatusCode) $($response.StatusDescription)"
}
catch {
    $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { $null }
    Add-Result HTTPS "https://$HostName`:$Port$Path" FAIL "HTTP=$status; $($_.Exception.Message)"
}

$dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses).ServerAddresses | Sort-Object -Unique
Add-Result LocalDNS $env:COMPUTERNAME INFO ($dnsServers -join ', ')

try {
    $proxy = (netsh winhttp show proxy | Out-String).Trim()
    Add-Result WinHTTPProxy $env:COMPUTERNAME INFO $proxy
} catch {}

if ($BackendServers) {
    foreach ($server in $BackendServers) {
        try {
            $test = Test-NetConnection -ComputerName $server -Port $Port -WarningAction SilentlyContinue
            Add-Result BackendTCP "$server`:$Port" ($(if($test.TcpTestSucceeded){'PASS'}else{'FAIL'})) "RemoteAddress=$($test.RemoteAddress)"
        }
        catch {
            Add-Result BackendTCP "$server`:$Port" FAIL $_.Exception.Message
        }
    }
}

$results | Format-Table -AutoSize -Wrap

if ($OutputPath) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved diagnostic evidence to $OutputPath" -ForegroundColor Green
}

<#
.SYNOPSIS
Read-only SCHANNEL / .NET TLS diagnostic for ClickOnce deployment failures.

.DESCRIPTION
Collects TLS 1.0/1.1/1.2/1.3 SCHANNEL registry state, .NET SchUseStrongCrypto settings,
current .NET SecurityProtocol, cipher suites, DNS resolution and TCP reachability. Run on a
working and affected device and compare results before changing TLS configuration.

SAFETY: READ-ONLY.

.PARAMETER HostName
FQDN of the ClickOnce/application endpoint, for example <application-hostname>.

.PARAMETER Port
HTTPS port the endpoint listens on. Defaults to 443.

.EXAMPLE
.\Get-ClickOnceTlsDiagnostic.ps1 -HostName '<application-hostname>' -Port 443
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HostName,
    [Parameter(Mandatory = $false)][int]$Port = 443
)

Write-Host "=== SCHANNEL / TLS Registry State ===" -ForegroundColor Cyan
foreach ($p in @("TLS 1.0", "TLS 1.1", "TLS 1.2", "TLS 1.3")) {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$p\Client"
    Write-Host "`n-- $p (Client) --"
    if (Test-Path $key) {
        Get-ItemProperty -Path $key | Select-Object Enabled, DisabledByDefault | Format-List
    } else {
        Write-Host "  (no explicit registry entry -- system default in effect)"
    }
}

Write-Host "`n=== .NET Framework SchUseStrongCrypto ===" -ForegroundColor Cyan
$netKeys = @{
    "64-bit" = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
    "32-bit" = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
}
foreach ($name in $netKeys.Keys) {
    $path = $netKeys[$name]
    Write-Host "`n$name`:"
    if (Test-Path $path) {
        $val = Get-ItemProperty -Path $path -Name "SchUseStrongCrypto" -ErrorAction SilentlyContinue
        if ($val) { Write-Host "  SchUseStrongCrypto = $($val.SchUseStrongCrypto)" }
        else { Write-Host "  SchUseStrongCrypto not set" }
    } else { Write-Host "  Key not found" }
}

Write-Host "`n=== Current .NET SecurityProtocol ===" -ForegroundColor Cyan
Write-Host "  $([Net.ServicePointManager]::SecurityProtocol)"

Write-Host "`n=== Available TLS Cipher Suites ===" -ForegroundColor Cyan
Get-TlsCipherSuite | Where-Object { $_.Name -like "*TLS*" } | Format-Table Name -AutoSize

Write-Host "`n=== DNS Resolution: $HostName ===" -ForegroundColor Cyan
Resolve-DnsName $HostName -ErrorAction SilentlyContinue

Write-Host "`n=== TCP Connectivity: $HostName`:$Port ===" -ForegroundColor Cyan
Test-NetConnection -ComputerName $HostName -Port $Port

<#
.SYNOPSIS
Verifies basic Azure App Service runtime and HTTPS reachability after a change.

.DESCRIPTION
Read-only verification that checks App Service state/default hostname and performs an HTTPS
request to the selected path. Useful after networking, deployment, TLS or configuration work.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$Name,
    [string]$Path = '/'
)

$ErrorActionPreference = 'Stop'
$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $Name
$app | Select-Object Name, State, DefaultHostName, HttpsOnly | Format-List

$uri = "https://$($app.DefaultHostName)$Path"
Write-Host "Testing $uri"
try {
    $r = Invoke-WebRequest -Uri $uri -Method Get -UseBasicParsing -TimeoutSec 30
    [pscustomobject]@{ Uri = $uri; StatusCode = $r.StatusCode; Result = 'Reachable' } | Format-List
} catch {
    [pscustomobject]@{ Uri = $uri; StatusCode = $null; Result = $_.Exception.Message } | Format-List
}

Write-Host 'Verification complete. No Azure resources were modified.'

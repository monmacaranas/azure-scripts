<#
.SYNOPSIS
Checks Azure Storage Account networking and Private Endpoint state.

.DESCRIPTION
Use this read-only script when troubleshooting Blob/Files access, Private Endpoint routing, public network restrictions, firewall rules, or App Service/AVD access to Azure Storage.

.REQUIREMENTS
Az.Accounts, Az.Storage, Az.Network
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$StorageAccountName
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

Write-Host "=== Storage Account ==="
$sa | Select-Object StorageAccountName, Location, Kind, Sku, EnableHttpsTrafficOnly, PublicNetworkAccess, AllowBlobPublicAccess, MinimumTlsVersion | Format-List

Write-Host "`n=== Network Rule Set ==="
$sa.NetworkRuleSet | Format-List

Write-Host "`n=== Private Endpoint Connections ==="
$sa.PrivateEndpointConnections |
    Select-Object PrivateEndpoint, PrivateLinkServiceConnectionState |
    Format-List

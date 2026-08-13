<#
.SYNOPSIS
Collects read-only Azure Storage Account security and networking configuration.

.DESCRIPTION
Use this script when investigating storage access, public exposure, Private Endpoint,
firewall, TLS, shared-key, or network-rule issues. It is intended for incident evidence,
security review, and before/after validation.

The script is read-only.

.EXAMPLE
.\Get-StorageAccountSecurityDiagnostic.ps1 -ResourceGroupName rg-storage -StorageAccountName mystorage
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$StorageAccountName,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$network = Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

$report = [ordered]@{
    Timestamp                   = (Get-Date).ToString('s')
    Name                        = $sa.StorageAccountName
    Location                    = $sa.Location
    Kind                        = $sa.Kind
    Sku                         = $sa.Sku
    HttpsTrafficOnly            = $sa.EnableHttpsTrafficOnly
    MinimumTlsVersion           = $sa.MinimumTlsVersion
    AllowBlobPublicAccess       = $sa.AllowBlobPublicAccess
    AllowSharedKeyAccess        = $sa.AllowSharedKeyAccess
    PublicNetworkAccess         = $sa.PublicNetworkAccess
    DefaultNetworkAction        = $network.DefaultAction
    Bypass                      = $network.Bypass
    IpRules                     = $network.IpRules
    VirtualNetworkRules         = $network.VirtualNetworkRules
    PrivateEndpointConnections  = $sa.PrivateEndpointConnections | Select-Object Id, PrivateLinkServiceConnectionState
    PrimaryBlobEndpoint         = $sa.PrimaryEndpoints.Blob
    PrimaryFileEndpoint         = $sa.PrimaryEndpoints.File
    PrimaryQueueEndpoint        = $sa.PrimaryEndpoints.Queue
    PrimaryTableEndpoint        = $sa.PrimaryEndpoints.Table
}

Write-Host "`n=== STORAGE ACCOUNT SECURITY / NETWORKING ===" -ForegroundColor Cyan
[pscustomobject]$report | Format-List

if ($OutputPath) {
    [pscustomobject]$report | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
    Write-Host "Saved report to $OutputPath" -ForegroundColor Green
}

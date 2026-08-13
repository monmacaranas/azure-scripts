<#
.SYNOPSIS
Collects Azure Storage Account configuration useful for troubleshooting connectivity and access.

.DESCRIPTION
Read-only evidence gathering for Storage Account incidents involving firewalls, public network
access, Private Endpoints, routing, encryption and RBAC-related access investigations.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts, Az.Storage, Az.Network and Az.Resources.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$StorageAccountName
)

$ErrorActionPreference = 'Continue'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop

Write-Host '=== Storage account ==='
$sa | Select-Object StorageAccountName, Location, Kind, SkuName, AccessTier,
    EnableHttpsTrafficOnly, MinimumTlsVersion, AllowBlobPublicAccess, PublicNetworkAccess,
    PrimaryEndpoints, Id | Format-List

Write-Host "`n=== Network rules ==="
try {
    Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $StorageAccountName |
        Format-List
} catch { Write-Warning $_.Exception.Message }

Write-Host "`n=== Private endpoint connections ==="
try {
    $sa.PrivateEndpointConnections |
        Select-Object Name, PrivateLinkServiceConnectionState, PrivateEndpoint |
        Format-List
} catch { Write-Warning $_.Exception.Message }

Write-Host "`n=== Role assignments at storage account scope ==="
try {
    Get-AzRoleAssignment -Scope $sa.Id |
        Select-Object DisplayName, SignInName, ObjectType, RoleDefinitionName, Scope |
        Sort-Object RoleDefinitionName, DisplayName |
        Format-Table -AutoSize
} catch { Write-Warning $_.Exception.Message }

Write-Host "`nCompleted. No Azure resources were modified."

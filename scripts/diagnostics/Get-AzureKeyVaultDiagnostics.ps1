<#
.SYNOPSIS
Collects Azure Key Vault configuration for access/network troubleshooting.

.DESCRIPTION
Read-only helper for incidents involving Key Vault firewall rules, public network access,
RBAC mode, soft delete, purge protection and Private Endpoint configuration.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$VaultName
)

$ErrorActionPreference = 'Stop'
$kv = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName
$kv | Select-Object VaultName, Location, ResourceId, EnableRbacAuthorization,
    PublicNetworkAccess, SoftDeleteRetentionInDays, EnablePurgeProtection,
    NetworkAcls, PrivateEndpointConnections | Format-List

Write-Host 'No Key Vault configuration or secrets were modified or displayed.'

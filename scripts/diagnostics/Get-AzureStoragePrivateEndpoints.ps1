<#
.SYNOPSIS
Shows Private Endpoint connections associated with an Azure Storage Account.

.DESCRIPTION
Read-only helper for storage connectivity investigations where blob/file endpoints may be
reachable only through Private Link.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$StorageAccountName
)

$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$sa.PrivateEndpointConnections |
    Select-Object Name, PrivateEndpoint, PrivateLinkServiceConnectionState |
    Format-List

Write-Host 'No Storage Account or Private Endpoint configuration was modified.'

<#
.SYNOPSIS
Verifies basic Azure Storage Blob access using the current Azure identity.

.DESCRIPTION
Read-only post-change check for storage RBAC/networking work. Attempts to enumerate blob
containers using Microsoft Entra authentication rather than account keys.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts and Az.Storage, plus an appropriate Storage Blob Data role.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$StorageAccountName
)

$ErrorActionPreference = 'Stop'
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

Write-Host "Testing Entra-authenticated blob access to $StorageAccountName"
Get-AzStorageContainer -Context $ctx |
    Select-Object Name, PublicAccess |
    Format-Table -AutoSize

Write-Host 'Verification complete. No storage data or Azure resources were modified.'

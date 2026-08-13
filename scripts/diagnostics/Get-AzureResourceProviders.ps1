<#
.SYNOPSIS
Shows Azure resource provider registration state.

.DESCRIPTION
Read-only helper for troubleshooting deployments that fail because a required Azure resource
provider is not registered in the subscription.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param()

Get-AzResourceProvider -ListAvailable |
    Select-Object ProviderNamespace, RegistrationState |
    Sort-Object ProviderNamespace |
    Format-Table -AutoSize

Write-Host 'No resource providers were registered or modified.'

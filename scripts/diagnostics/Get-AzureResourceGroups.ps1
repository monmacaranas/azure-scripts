<#
.SYNOPSIS
Lists Azure resource groups with location and provisioning state.

.DESCRIPTION
Read-only helper for environment inventory, handover review and confirming the correct
resource group before troubleshooting or making changes.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param()

Get-AzResourceGroup |
    Select-Object ResourceGroupName, Location, ProvisioningState, ResourceId |
    Sort-Object ResourceGroupName |
    Format-Table -AutoSize

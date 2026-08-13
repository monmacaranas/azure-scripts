<#
.SYNOPSIS
Lists Azure locations available to the current subscription.

.DESCRIPTION
Read-only helper for deployment planning and troubleshooting regional availability.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param()

Get-AzLocation |
    Select-Object Location, DisplayName, GeographyGroup, PhysicalLocation |
    Sort-Object DisplayName |
    Format-Table -AutoSize

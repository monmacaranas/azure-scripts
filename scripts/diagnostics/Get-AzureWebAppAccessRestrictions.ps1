<#
.SYNOPSIS
Displays Azure App Service access restriction configuration.

.DESCRIPTION
Read-only helper for investigating 403 responses and IP/VNet access issues on App Service.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$Name
)

$ErrorActionPreference = 'Stop'
$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $Name

Write-Host '=== Main site access restrictions ==='
$app.SiteConfig.IpSecurityRestrictions |
    Select-Object Priority, Name, Action, IpAddress, VnetSubnetResourceId, Tag, Description |
    Sort-Object Priority |
    Format-Table -AutoSize

Write-Host "`n=== SCM access restrictions ==="
$app.SiteConfig.ScmIpSecurityRestrictions |
    Select-Object Priority, Name, Action, IpAddress, VnetSubnetResourceId, Tag, Description |
    Sort-Object Priority |
    Format-Table -AutoSize

Write-Host 'No App Service access restrictions were modified.'

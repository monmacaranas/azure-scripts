<#
.SYNOPSIS
Displays Azure App Service Plan configuration and worker sizing.

.DESCRIPTION
Read-only helper for App Service performance, scaling and cost investigations.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$Name
)

$plan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $Name
$plan | Select-Object Name, Location, Status, Sku, WorkerSize, NumberofWorkers,
    MaximumNumberofWorkers, PerSiteScaling, Reserved, IsSpot | Format-List

Write-Host 'No App Service Plan configuration was modified.'

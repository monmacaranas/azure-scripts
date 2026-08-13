<#
.SYNOPSIS
Creates a read-only Azure resource inventory to support retirement and deprecation assessments.

.DESCRIPTION
Use this script when Microsoft announces an Azure service, SKU, API, runtime, or feature
retirement and you first need a reliable inventory of potentially affected resources.

This script does not attempt to decide whether every resource is impacted by a specific
retirement. Instead, it produces a searchable inventory from Azure Resource Graph containing
resource type, API-relevant kind/SKU/properties where available, subscription, resource
group, location, and resource ID. Use the -TypeContains parameter to narrow the inventory
to the service family being assessed.

This is particularly useful before deadlines where the first task is determining scope,
owners, and affected environments.

.REQUIREMENTS
- Az.ResourceGraph
- Reader access to the target subscriptions

.EXAMPLE
.\Get-AzureResourceRetirementInventory.ps1 -SubscriptionIds @('<subscription-id>') -TypeContains 'Microsoft.Sql'

.EXAMPLE
.\Get-AzureResourceRetirementInventory.ps1 -SubscriptionIds @('<sub1>','<sub2>') -TypeContains 'Microsoft.Network/applicationGateways' -OutputPath .\appgateway-inventory.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$SubscriptionIds,
    [string]$TypeContains,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Az.ResourceGraph)) {
    throw 'Az.ResourceGraph is required. Install-Module Az.ResourceGraph -Scope CurrentUser'
}

$query = @"
resources
| project subscriptionId, resourceGroup, name, type, kind, location, sku=tostring(sku.name), resourceId=id, properties
"@

$rows = Search-AzGraph -Query $query -Subscription $SubscriptionIds -First 5000

if ($TypeContains) {
    $rows = $rows | Where-Object { $_.type -like "*$TypeContains*" }
}

$rows = $rows | Select-Object subscriptionId, resourceGroup, name, type, kind, location, sku, resourceId

$rows | Sort-Object type, resourceGroup, name | Format-Table -AutoSize -Wrap

if ($OutputPath) {
    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved retirement-assessment inventory to $OutputPath" -ForegroundColor Green
}

<#
.SYNOPSIS
Checks key Azure App Service health and configuration settings.

.DESCRIPTION
Use this read-only script when troubleshooting App Service slowness, CPU or memory pressure, failed requests, VNet integration, HTTPS/FTPS state, or production availability. It provides a concise health snapshot suitable for incident notes and Jira updates.

.REQUIREMENTS
Az.Accounts, Az.Websites
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$WebAppName
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName

[pscustomobject]@{
    Name            = $app.Name
    State           = $app.State
    Location        = $app.Location
    DefaultHostName = $app.DefaultHostName
    HttpsOnly       = $app.HttpsOnly
    FtpsState       = $app.SiteConfig.FtpsState
    AlwaysOn        = $app.SiteConfig.AlwaysOn
    MinTlsVersion   = $app.SiteConfig.MinTlsVersion
    VnetRouteAllEnabled = $app.SiteConfig.VnetRouteAllEnabled
    ResourceId      = $app.Id
} | Format-List

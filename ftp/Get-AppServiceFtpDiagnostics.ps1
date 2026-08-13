<#
.SYNOPSIS
Collects FTP/FTPS-related diagnostic configuration for an Azure App Service.

.DESCRIPTION
Use this read-only script for production FTP connection investigations and alert design. It captures App Service FTP state, diagnostic settings, available log categories, and relevant configuration needed to determine whether FTP/FTPS activity can be monitored through Azure Monitor or App Service logs.

.REQUIREMENTS
Az.Accounts, Az.Websites, Az.Monitor

.EXAMPLE
.\Get-AppServiceFtpDiagnostics.ps1 -ResourceGroupName "rg-prod" -WebAppName "app-prod"
#>

param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$WebAppName,

    [string]$OutputPath = ".\ftp-diagnostics-$WebAppName-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
)

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount }

$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
$resourceId = $app.Id
$config = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("App Service: $WebAppName")
$lines.Add("Resource Group: $ResourceGroupName")
$lines.Add("Resource ID: $resourceId")
$lines.Add("State: $($app.State)")
$lines.Add("Host Names: $($app.HostNames -join ', ')")
$lines.Add("HttpsOnly: $($app.HttpsOnly)")
$lines.Add("FTPS State: $($app.SiteConfig.FtpsState)")
$lines.Add("")
$lines.Add("Existing diagnostic settings:")

$settings = Get-AzDiagnosticSetting -ResourceId $resourceId -ErrorAction SilentlyContinue
foreach ($setting in $settings) {
    $lines.Add("- $($setting.Name) | Workspace: $($setting.WorkspaceId) | Storage: $($setting.StorageAccountId)")
}

$lines.Add("")
$lines.Add("Available diagnostic categories:")
$categories = Get-AzDiagnosticSettingCategory -ResourceId $resourceId -ErrorAction SilentlyContinue
foreach ($category in $categories) {
    $lines.Add("- $($category.Name) [$($category.CategoryType)]")
}

$lines | Set-Content -Path $OutputPath
$lines | ForEach-Object { Write-Host $_ }

Write-Host "`nDiagnostic snapshot saved to $OutputPath"

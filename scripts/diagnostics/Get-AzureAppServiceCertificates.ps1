<#
.SYNOPSIS
Inventories Azure App Service certificates for expiration and binding reviews.

.DESCRIPTION
Read-only helper for TLS/certificate troubleshooting and expiry reviews. Does not export
certificate content or private keys.

SAFETY: READ-ONLY.
#>
[CmdletBinding()]
param([string]$ResourceGroupName)

$certs = if ($ResourceGroupName) { Get-AzWebAppCertificate -ResourceGroupName $ResourceGroupName } else { Get-AzWebAppCertificate }

$certs | Select-Object Name, ResourceGroupName, HostNames, Issuer, SubjectName,
    IssueDate, ExpirationDate, Thumbprint |
    Sort-Object ExpirationDate |
    Format-Table -AutoSize

Write-Host 'No certificates or private keys were modified or exported.'

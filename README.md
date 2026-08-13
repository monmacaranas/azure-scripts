# Azure & Infra Scripts

A working collection of PowerShell, Bash, Azure CLI, and reference code used for troubleshooting, verification, automation, and recovery across Azure infrastructure.

The purpose of this repository is practical: troubleshooting commands and small operational automations should not live only in chat histories, tickets, or one-off terminal sessions. When the same DNS check, storage test, role-assignment fix, SQL capacity investigation, FTP diagnostic, or rollback is needed again, it should already exist here as a reusable script.

Nothing in this repository should contain passwords, access keys, client secrets, certificates, SAS tokens, or other credentials. Resource names shown in examples are operational examples only; replace them with the correct values for the environment being investigated.

## How this repository is used

The scripts are primarily used for:

- Azure incident troubleshooting and evidence collection
- DNS, routing, TCP, Private Endpoint, and Application Gateway investigations
- Azure Storage and App Service connectivity troubleshooting
- Azure SQL capacity and quota investigations
- FTP/FTPS production connectivity troubleshooting and alert PoC work
- Managed Identity and RBAC verification
- Azure Automation and Defender for Cloud operational tasks
- Configuration verification before and after changes
- Controlled rollback procedures
- Collecting evidence for Jira tickets, change records, incident reports, and technical documentation

## Layout

```text
scripts/
  automation/     Scheduled or repeatable Azure operational automation
  diagnostics/    Read-only troubleshooting and evidence collection
  verification/   Read-only checks that confirm a specific configuration
  rollback/       Controlled scripts that can change live state and should be reviewed first
snippets/         Reference code patterns rather than standalone operational scripts
```

## Script catalogue

### scripts/diagnostics/

**`Get-AzureNetworkDiagnostic.ps1`**

General-purpose first-response network diagnostic for Azure-hosted applications and endpoints. Collects DNS resolution, TCP connectivity, local IP/DNS configuration, IPv4 routes, WinHTTP proxy configuration, and optionally an HTTPS request result.

Use it for issues involving Application Gateway, IFS/ClickOnce, App Service, Private Endpoints, Azure Storage, APIs, or other services that appear unreachable from a Windows client or server. The purpose is to gather evidence before changing NSGs, UDRs, Azure Firewall, Private DNS, Application Gateway, or application configuration.

Example:

```powershell
.\Get-AzureNetworkDiagnostic.ps1 -HostName ifs10.abc.world -Port 48080 -HttpsPath /admin
```

**`Get-FtpDiagnostic.ps1`**

Read-only FTP/FTPS/SFTP connectivity evidence collector. Tests DNS and selected ports such as 21, 22, and 990, and records the local DNS, routing, and proxy state.

Use it for production FTP incidents and for work such as ITP-346 where the available FTP diagnostic/log source and connection alert design need to be established before implementing monitoring. It deliberately does not authenticate or handle FTP credentials.

Example:

```powershell
.\Get-FtpDiagnostic.ps1 -HostName ftp.example.com -Ports 21,22,990
```

**`Get-PrivateEndpointDnsDiagnostic.ps1`**

Checks normal and Private Link DNS resolution for a resource and can query a specific DNS server directly. Also performs a TCP 443 test against the service FQDN.

Use it when a VM, AVD host, pipeline agent, or application resolves an Azure service incorrectly after Private Endpoint deployment. Useful for Azure Storage, SQL, Key Vault, App Service, and similar Private Link-enabled services before changing Private DNS zones, VNet links, custom DNS servers, or forwarders.

Example:

```powershell
.\Get-PrivateEndpointDnsDiagnostic.ps1 `
  -HostName mystorage.blob.core.windows.net `
  -PrivateLinkHostName mystorage.privatelink.blob.core.windows.net `
  -DnsServer 10.0.3.4
```

**`Get-AzureSqlDatabaseCapacity.ps1`**

Reports the current Azure SQL Database service tier, configured maximum size, recent storage usage, and utilization percentage.

Use this when Azure Data Factory, ETL, or application activity fails with errors such as "database has reached its size quota." It provides the information needed to decide whether to increase database storage, scale the tier, clean up data, review indexes, or configure warning/critical alerts.

Example:

```powershell
.\Get-AzureSqlDatabaseCapacity.ps1 `
  -ResourceGroupName rg-data `
  -ServerName sql-prod `
  -DatabaseName appdb
```

**`Test-StorageConnectivity.ps1`**

DNS, ping, and TCP 443 checks for "cannot reach the storage account" symptoms from a client machine, with or without VPN connectivity.

Use it to determine whether an Azure Storage problem is actually at the network layer before changing firewall rules, Private Endpoints, DNS, or application configuration.

### scripts/verification/

**`verify-cross-subscription-identity.sh`**

Confirms the key pieces of a cross-subscription Managed Identity configuration: identity availability, RBAC assignment in the target subscription, and a live authorization test against the target resource.

Use it when an application or Azure resource uses a managed identity to access a resource located in another subscription.

**`inspect-app-service-storage-config.sh`**

First-pass inspection of App Service configuration related to Azure Storage. Reviews outbound IP information, VNet integration, and application settings that reference Storage or Key Vault.

Use it before assuming a storage access failure is caused by networking.

### scripts/automation/

**`Invoke-SqlVaBaselineAcceptance.ps1`**

Azure Automation runbook for accepting Microsoft Defender for Cloud SQL Vulnerability Assessment findings as the current baseline across databases on a SQL server. Runs under a System-Assigned Managed Identity.

Review the script notes before scheduling it in a new environment. Baselining marks the current state as expected, so it should be used only when the security implications are understood.

**`Grant-SqlVaRunbookPermissions.ps1`**

One-time setup script that grants the Azure Automation Account managed identity the Azure roles required by the SQL Vulnerability Assessment runbook.

### scripts/rollback/

**`rollback-managed-identity-storage-auth.sh`**

Emergency rollback procedure for a Managed Identity-based Azure Storage authentication migration. It is designed to restore the previous access model when a deployment must be backed out.

This script changes live configuration. Read it completely, verify the target resources, and confirm that rollback is actually required before execution.

### snippets/

**`BlobStorageService.DefaultAzureCredential.cs`**

Reference C# pattern for authenticating to Azure Blob Storage with `DefaultAzureCredential` rather than a storage account key or connection string.

Use it as a development reference when moving applications toward Managed Identity / Microsoft Entra authentication.

## Operating conventions

- Diagnostic and verification scripts should be read-only wherever possible.
- A script that changes live state should make that fact obvious in its header and should include safeguards or confirmation where practical.
- Every script should explain **why it exists**, the incident or operational scenario it supports, and what type of evidence or change it produces.
- Replace example resource names before execution.
- Never commit credentials, access keys, secrets, certificates, SAS tokens, or exported authentication context.
- Prefer parameterized scripts rather than hardcoded tenant, subscription, resource-group, or resource names.
- Save generated diagnostic output with the related Jira ticket or incident when useful.
- Test change-producing scripts in a non-production environment before production use whenever possible.

## Common troubleshooting sequence

For most Azure connectivity incidents, use this order:

1. Confirm the target hostname and expected port.
2. Check DNS resolution.
3. Test TCP connectivity.
4. Check local DNS servers, routing, VPN, and proxy configuration.
5. Verify Azure-side networking: NSG, UDR, firewall, Private Endpoint, Private DNS, VNet integration, or Application Gateway.
6. Verify identity and RBAC if network connectivity succeeds but authorization fails.
7. Capture the result in the relevant incident/Jira ticket before applying a production change.
8. After the fix, rerun the same diagnostic script to produce before/after evidence.

## Adding new scripts

When a troubleshooting command or operational procedure is likely to be used again, convert it into a reusable script and add it to the appropriate folder.

Each new script should include:

- Synopsis
- Description and operational purpose
- Whether it is read-only or changes live state
- Required modules/tools
- Parameters instead of hardcoded values where possible
- One or more usage examples
- Notes about production risk or rollback where applicable

The repository should remain a practical Azure operations toolbox: quick to search, safe to reuse, and useful during real incidents.

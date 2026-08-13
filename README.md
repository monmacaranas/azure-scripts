# Azure & Infrastructure Scripts

A working collection of PowerShell, Bash, Azure CLI, KQL, SQL and reference code used for Azure troubleshooting, verification, operational tasks and controlled automation.

The purpose of this repository is to turn repeatable troubleshooting steps and operational work into reusable scripts instead of leaving them only in chat history, Jira tickets or engineer notes.

## Layout

```text
scripts/
  automation/     Scheduled/production automation — test before scheduling
  diagnostics/    Read-only troubleshooting/data collection — safe starting point
  verification/   Read-only checks that confirm a specific configuration or remediation
  rollback/       Makes live changes — requires review and confirmation
snippets/         Reference code/query patterns, not standalone production automation
```

## Safety convention

- **Diagnostics** are read-only evidence-gathering scripts.
- **Verification** scripts are read-only post-change checks.
- **Automation** scripts are intended for repeatable operational work but must be tested first.
- **Rollback** scripts change live Azure state and must never be run blindly.
- **Snippets** are reusable examples and may require environment-specific adaptation.

Never commit passwords, connection strings, SAS tokens, storage keys, service-principal secrets, access tokens, PFX files, certificates or private keys.

## Script catalogue

### scripts/automation/

**`Invoke-SqlVaBaselineAcceptance.ps1`**  
Azure Automation runbook for Microsoft Defender for Cloud SQL Vulnerability Assessment baseline acceptance across databases. Read the script warnings carefully: baselining accepts the current state; it does not remediate findings.

**`Grant-SqlVaRunbookPermissions.ps1`**  
One-time role setup for the SQL VA Automation Account managed identity. Grants the permissions required by the baseline runbook.

### scripts/diagnostics/

**`Get-AzureResourceHealthSnapshot.ps1`**  
Quick subscription/resource inventory for the start of an incident, handover review or unfamiliar environment investigation. Summarizes resources by type, location and resource group.

**`Get-AzureNetworkDiagnostic.ps1`**  
General Windows-side network troubleshooting. Collects DNS resolution, TCP connectivity, IP configuration, DNS client configuration, route table, WinHTTP proxy and an optional HTTPS request. Useful for Application Gateway, Private Endpoint, storage, App Service, IFS/ClickOnce and general connectivity investigations.

**`Test-StorageConnectivity.ps1`**  
Fast storage-account DNS and TCP 443 test used to distinguish network problems from application/authentication problems.

**`Get-AzureFtpDiagnosticSources.ps1`**  
Discovers available diagnostic settings, diagnostic categories and App Service FTP/FTPS-related configuration. Used when establishing the telemetry source for production FTP connection alerts and troubleshooting.

**`Get-AzurePrivilegedRoleInventory.ps1`**  
Inventories high-impact Azure RBAC assignments such as Owner, Contributor, User Access Administrator and RBAC Administrator. Useful for privileged access reviews and identifying candidates for Microsoft Entra PIM.

**`Get-AzureSqlDatabaseCapacity.ps1`**  
Collects Azure SQL Database service tier, service objective, configured maximum size and elastic-pool information when troubleshooting database size-quota or ADF sink failures.

**`Get-AzureDiagnosticSettings.ps1`**  
Shows supported Azure Monitor diagnostic categories and configured destinations such as Log Analytics, Storage and Event Hub. Useful when expected logs are missing or before creating an alert.

**`Get-AzureAppServiceDiagnostics.ps1`**  
Collects App Service state, outbound IPs, identity, TLS/FTPS configuration, VNet integration and diagnostic settings for incident troubleshooting.

### scripts/verification/

**`Test-AzurePrivateEndpointDns.ps1`**  
Checks service FQDN resolution, private IP classification and TCP connectivity after Private Endpoint, Private DNS, DNS forwarder or VNet peering changes.

**`verify-cross-subscription-identity.sh`**  
Read-only verification for cross-subscription Managed Identity and Storage RBAC configuration.

**`inspect-app-service-storage-config.sh`**  
First-pass Azure CLI inspection of App Service outbound IPs, VNet integration and storage/Key Vault-related application settings.

### scripts/rollback/

**`rollback-managed-identity-storage-auth.sh`**  
Emergency rollback helper for a Managed Identity storage-auth migration. **Makes live changes** and requires an explicit confirmation prompt.

### snippets/

**`BlobStorageService.DefaultAzureCredential.cs`**  
Reference C# pattern for authenticating to Azure Blob Storage with `DefaultAzureCredential` rather than a connection string or account key.

**`AzureMonitor-Http5xxThreshold.kql`**  
Application Insights/Azure Monitor example query for detecting HTTP 5xx result codes above a threshold in five-minute bins.

**`AzureSql-DatabaseCapacity-Queries.sql`**  
Read-only SQL queries for database file size, used/reserved space and identifying the largest tables during size-quota investigations.

## Recommended troubleshooting workflow

1. Start with a script under `scripts/diagnostics/` and collect evidence before changing Azure configuration.
2. Save the relevant output in the incident, Jira ticket or technical documentation.
3. Implement the required Azure change through the approved process.
4. Run the appropriate `scripts/verification/` check after the change.
5. Only move a task into `scripts/automation/` after it has been tested and shown to be safe to run repeatedly.
6. Keep rollback/remediation scripts separate from diagnostics so an investigation cannot accidentally modify production.

## Common prerequisites

PowerShell scripts may require modules such as:

```powershell
Install-Module Az.Accounts
Install-Module Az.Resources
Install-Module Az.Monitor
Install-Module Az.Websites
Install-Module Az.Sql
Install-Module Az.Automation
```

Bash scripts require Azure CLI and an authenticated session:

```bash
az login
az account show
```

## Adding scripts

Every standalone script should include:

- purpose and troubleshooting/task use case
- safety classification: read-only or modifies Azure
- prerequisites and required permissions
- parameters
- expected output
- example usage
- production risk or rollback considerations where applicable

Placeholders such as `<resource-group>` and `<storage-account-name>` must be replaced before running. Credentials and secrets must never be hardcoded in the repository.
  automation/     Scheduled or repeatable operational automation
  diagnostics/    Read-only troubleshooting and evidence collection
  verification/   Read-only configuration, access, security and compliance checks
  rollback/       Controlled scripts that can change live state
snippets/         Reference code patterns rather than standalone scripts
```

## Script catalogue

### Diagnostics

| Script | Purpose |
|---|---|
| `Get-AzureNetworkDiagnostic.ps1` | General DNS, TCP, routing, proxy and HTTPS first-response troubleshooting for Azure-hosted endpoints. |
| `Test-IfsConnectivity.ps1` | IFS/ClickOnce connectivity checks including DNS, TCP 48080, HTTPS, expected Application Gateway IP and optional backend-server tests. |
| `Get-AppGatewayDiagnostic.ps1` | Application Gateway SKU, frontend, listeners, pools, HTTP settings, probes, routing, TLS certificates and backend-health collection. |
| `Get-FtpDiagnostic.ps1` | FTP/FTPS/SFTP DNS and port connectivity evidence collection for incidents and connection-alert PoC work. |
| `Get-PrivateEndpointDnsDiagnostic.ps1` | Compares service and Private Link DNS resolution, including optional direct queries to an internal DNS server. |
| `Get-PrivateDnsZoneReport.ps1` | Reports Private DNS zones, VNet links and A records for Private Endpoint troubleshooting. |
| `Test-StorageConnectivity.ps1` | DNS, ping and TCP 443 checks for Azure Storage connectivity investigations. |
| `Get-StorageAccountSecurityDiagnostic.ps1` | Storage firewall, public access, TLS, shared-key, network rules and Private Endpoint security review. |
| `Get-AppServiceHealthDiagnostic.ps1` | App Service state, plan, outbound IPs, VNet integration and storage-relevant configuration inspection. |
| `Get-AzureSqlDatabaseCapacity.ps1` | Azure SQL tier, configured size, storage usage and quota-utilization investigation. |

### Verification and reporting

| Script | Purpose |
|---|---|
| `Get-AzureRoleAssignmentsReport.ps1` | Inventory Owner, Contributor and other high-impact RBAC assignments for privileged-access/PIM reviews. |
| `Get-AzureDeveloperAccessReport.ps1` | Inventory designated developer object IDs across Corp, Prod or other Azure scopes. |
| `Get-AzureDefenderFindings.ps1` | Export active Microsoft Defender for Cloud recommendations using Azure Resource Graph. |
| `Get-AzureSqlRetentionStatus.ps1` | Report Azure SQL short-term and long-term backup-retention configuration. |
| `Get-AzureResourceRetirementInventory.ps1` | Build a searchable Azure resource inventory for service/API/SKU retirement assessments. |
| `verify-cross-subscription-identity.sh` | Verify Managed Identity and RBAC access across subscriptions, including a live authorization test. |
| `inspect-app-service-storage-config.sh` | Inspect App Service outbound IP, VNet integration and Storage/Key Vault-related settings. |

### Automation

| Script | Purpose |
|---|---|
| `Invoke-SqlVaBaselineAcceptance.ps1` | Azure Automation runbook for SQL Vulnerability Assessment baseline acceptance. Review security implications before scheduling. |
| `Grant-SqlVaRunbookPermissions.ps1` | One-time RBAC setup for the SQL VA Automation Account managed identity. |

### Rollback

| Script | Purpose |
|---|---|
| `rollback-managed-identity-storage-auth.sh` | Controlled rollback for a Managed Identity-based Azure Storage authentication migration. **Changes live state.** |

### Snippets

| File | Purpose |
|---|---|
| `BlobStorageService.DefaultAzureCredential.cs` | C# reference pattern for Blob Storage authentication using `DefaultAzureCredential` instead of account keys/connection strings. |

## Common troubleshooting workflow

1. Confirm the target resource, hostname and expected port.
2. Check DNS resolution and expected private/public IP.
3. Test TCP connectivity.
4. Check local DNS servers, routing, VPN and proxy configuration.
5. Inspect Azure networking: NSG, UDR, Azure Firewall, Private Endpoint, Private DNS, VNet integration and Application Gateway.
6. If networking succeeds, verify identity, RBAC and application authorization.
7. Capture output as incident/Jira evidence before making production changes.
8. Apply the approved fix.
9. Re-run the same diagnostic to provide before/after evidence.

## Operating conventions

- Diagnostic and verification scripts should remain read-only wherever possible.
- Change-producing scripts must clearly state their impact and include safeguards or confirmation when practical.
- Every script should explain **why it exists**, not just what commands it runs.
- Prefer parameters over hardcoded subscription IDs, resource groups, resource names and tenant values.
- Save useful output with the related Jira ticket, change record, incident report or technical documentation.
- Test change-producing scripts in non-production before production use whenever possible.
- Review scripts before execution; this repository is an engineering toolbox, not a substitute for change control.

## Adding new scripts

When a troubleshooting command or operational procedure is likely to be reused, convert it into a script and add it to the appropriate folder. Include a synopsis, operational purpose, requirements, parameters, examples, read-only/change impact, and production-risk notes.

The repository should stay quick to search, safe to reuse, and useful during real Azure incidents.

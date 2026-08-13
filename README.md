# Azure & Infrastructure Scripts

A working collection of PowerShell, Bash, Azure CLI, KQL and reference code used for Azure troubleshooting, verification, operational tasks and controlled automation.

The purpose of this repository is to turn repeatable troubleshooting steps and operational work into reusable scripts instead of leaving them only in chat history, Jira tickets or engineer notes.

## Layout

```text
scripts/
  automation/     Scheduled/production automation — test before scheduling
  diagnostics/    Read-only troubleshooting/data collection — safe starting point
  verification/   Read-only checks that confirm a specific configuration or remediation
  rollback/       Makes live changes — requires review and confirmation
snippets/         Reference code patterns, not standalone runnable scripts
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

# Azure & Infra Scripts

A practical collection of PowerShell, Bash, Azure CLI, and reference code used for Azure troubleshooting, verification, automation, security review, and recovery.

The goal is simple: useful commands should not live only in chat histories, Jira tickets, incident notes, or one-off terminal sessions. If a DNS check, RBAC review, SQL investigation, Application Gateway diagnostic, Private Endpoint test, or rollback is useful more than once, it belongs here as a reusable script.

> **Security:** Never commit passwords, access keys, client secrets, certificates, SAS tokens, or exported authentication context. Scripts should be parameterized and should clearly state whether they are read-only or change live Azure configuration.

## Layout

```text
scripts/
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
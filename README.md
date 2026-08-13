# Azure Scripts

Reusable PowerShell and KQL scripts for Azure administration, troubleshooting, diagnostics, security reviews, monitoring, and operational support.

This repository is intended as a practical runbook library for day-to-day Azure engineering work. Scripts are written to be parameterized and reusable across environments. Do not store passwords, client secrets, access keys, SAS tokens, private certificates, or other credentials in this repository.

## Repository structure

- `troubleshooting/` — connectivity, DNS, App Service, Storage, SQL, and resource diagnostics.
- `security/` — Azure RBAC, Defender for Cloud, privileged-access and permission review helpers.
- `monitoring/` — Azure Monitor, diagnostic settings, alerts, Log Analytics and KQL.
- `networking/` — VNet, subnet, NSG, Private Endpoint and DNS checks.
- `sql/` — Azure SQL capacity, retention and health checks.
- `storage/` — Storage Account, Blob and Private Endpoint diagnostics.
- `app-service/` — App Service configuration and connectivity diagnostics.
- `ftp/` — FTP/FTPS production connection logging and alert discovery.

## How to use

1. Review the script header and prerequisites.
2. Sign in to the correct Azure tenant/subscription using `Connect-AzAccount` or Azure CLI as required.
3. Use read-only scripts first when troubleshooting production.
4. Validate subscription, resource group and resource names before running any command that changes configuration.
5. Save investigation output to a ticket or incident record when evidence is required.

## Common prerequisites

Most PowerShell scripts use the Az modules:

```powershell
Install-Module Az -Scope CurrentUser
```

Some scripts use Azure CLI:

```powershell
az login
az account set --subscription "<subscription-id-or-name>"
```

## Safety

Scripts in this repository are operational aids. Always review commands before using them in production. Diagnostic scripts are designed to be read-only unless clearly labelled otherwise.

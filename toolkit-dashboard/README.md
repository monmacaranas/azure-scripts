# AZURE OPERATIONS TOOLKIT

A lightweight dashboard front end for the scripts in the parent `azure-scripts` repository.

The dashboard does **not** contain credentials and does not execute Azure commands in the browser. It presents the approved script paths, short operational descriptions and copy-ready commands so an engineer can select a troubleshooting task quickly and run it from PowerShell after reviewing the parameters.

## Tasks

1. Network / DNS Diagnostic
2. Storage Connectivity
3. Private Endpoint Diagnostic
4. Application Gateway Diagnostic
5. App Service Diagnostic
6. Azure SQL Capacity
7. FTP Connection Diagnostic
8. RBAC / Privileged Access Report
9. Defender Findings
10. SQL Retention Report
11. Azure Retirement Inventory

## Open the dashboard locally

From the repository root on Windows:

```powershell
Start-Process .\toolkit-dashboard\index.html
```

Or double-click `toolkit-dashboard/index.html`.

## Normal operating flow

```powershell
git pull
Connect-AzAccount
Get-AzSubscription
Set-AzContext -Subscription "<subscription-name-or-id>"
Start-Process .\toolkit-dashboard\index.html
```

Choose a task, copy the displayed command, replace the placeholders with approved environment values, review the script header, and run the command from PowerShell.

## Safety

- The dashboard is a launcher/reference interface, not an Azure credential store.
- Never put tenant secrets, client secrets, passwords, keys, SAS tokens, certificates or exported auth contexts into the HTML.
- Resource identifiers should be supplied at execution time and should not be hardcoded into the dashboard.
- Diagnostic and verification tasks are expected to be read-only.
- Any future automation, rollout or rollback action that changes Azure must be clearly identified and remain subject to normal change control.

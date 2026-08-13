# Azure & Infra Scripts

A working collection of the PowerShell, Bash, and reference code I use for troubleshooting
and automating Azure infrastructure — not tied to one project or client. Nothing here is
theoretical: every script grew out of a real ticket or a real deployment, and the comments
at the top of each file explain the "why," not just the "what." Where a script references a
specific tenant or resource name, that's just the real example it came from — the logic
generalizes to any Azure environment; swap in your own names.

**Purpose:** so a troubleshooting step or small automation doesn't live only in a chat
history or a ticket comment. When the same connectivity check, role-assignment fix, or
rollback shows up a second time, it should be a script you run, not a set of steps you
reconstruct from memory.

## Layout

```
scripts/
  automation/     Scheduled/production automation — safe to run repeatedly, low blast radius
  diagnostics/    Read-only checks — safe to run any time, changes nothing
  verification/   Read-only checks that confirm a specific config is correct
  rollback/       Makes live changes — reads a confirmation prompt before doing anything
snippets/         Reference code patterns, not standalone runnable scripts
```

As this grows past Azure, add top-level folders alongside `scripts/` (e.g. `m365/`,
`general/`) rather than nesting everything under an `azure/` prefix — keeps each category
easy to find without renaming what's already here.

## What's in here

### scripts/automation/

**`Invoke-SqlVaBaselineAcceptance.ps1`**
Weekly Azure Automation runbook that automates "Add all results as baseline" for Microsoft
Defender for Cloud's SQL Vulnerability Assessment, across every database on a SQL server —
one REST call per database instead of one portal click per finding per database. Runs under
a System-Assigned Managed Identity. Read the `.NOTES` block before scheduling this anywhere
new — baselining marks the *current* state as expected, so a genuinely new/unexpected
finding gets silently accepted on the next run unless something else is watching for it.

**`Grant-SqlVaRunbookPermissions.ps1`**
One-time setup: grants the Automation Account's managed identity the `Reader` and
`SQL Security Manager` roles the runbook above needs on a target SQL server.

### scripts/diagnostics/

**`Test-StorageConnectivity.ps1`**
DNS/ping/TCP-443 checks for "can't reach the storage account" symptoms from a client
machine, with or without VPN connected. Written after several connectivity tickets that all
*looked* network-related and turned out not to be — this is the fast way to rule the network
layer in or out before chasing a firewall or Private Endpoint theory that isn't the actual
cause.

### scripts/verification/

**`verify-cross-subscription-identity.sh`**
Confirms all three pieces of a cross-subscription Managed Identity setup are actually in
place: the identity is enabled, the RBAC role assignment exists in the *target* subscription
(easy to check in the wrong one), and a live auth test against the resource succeeds.

**`inspect-app-service-storage-config.sh`**
First-pass sweep of an App Service's storage-relevant configuration — outbound IPs (for
firewall allow-lists), VNet integration state, and any app settings referencing storage or
Key Vault. Good starting point before assuming a network cause.

### scripts/rollback/

**`rollback-managed-identity-storage-auth.sh`**
Emergency rollback for a Managed-Identity storage-auth migration: re-opens blob public
access and removes the app's managed identity so a previous connection-string-based
deployment works again. **Makes live changes** — it prompts for confirmation and is meant to
be read, not blindly executed, since the actual code rollback (redeploying the old build)
still has to happen separately.

### snippets/

**`BlobStorageService.DefaultAzureCredential.cs`**
Reference C# pattern for authenticating to Blob Storage with `DefaultAzureCredential`
instead of a connection string or account key. Not a standalone script; copy the parts you
need.

## Conventions

- Every script's header explains *why* it exists, not just what it does — the context is
  usually more useful than the command itself six months later.
- Diagnostic and verification scripts are read-only by design. Anything that changes live
  state (automation runbooks aside, which are meant to run unattended) asks for confirmation
  first.
- Placeholders like `<resource-group>`, `<storage-account-name>` are literal — replace them
  before running. Nothing in this repo hardcodes a credential, key, or secret.
- PowerShell for anything that runs as an Azure Automation runbook or targets a Windows dev
  machine; Bash/`az cli` for anything meant to run from a terminal against the CLI directly.

## Adding to this repo

New script → new file under the right subfolder (or a new top-level folder for a new
category), a header comment explaining the "why," and a short entry in this README. If it
makes live changes, add a confirmation prompt like the one in `rollback/`.

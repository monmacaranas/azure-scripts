# ITP-233 - AEA failover-side elastic-pool placement automation

## Scope

Automate correction of the AEA geo-secondary database's elastic-pool placement based on the corresponding ASE primary database's current pool.

**Hard safety boundary:** the runbook never writes to `sql-paas-ase-safetrac-prd`, never changes ASE database placement, and never adds/removes/edits failover-group membership.

## Why Azure behaves this way

Azure SQL failover groups manage database replication between logical servers. Elastic-pool placement on the secondary is a separate placement setting. For pooled databases, Microsoft requires the corresponding secondary pool to exist and explains that secondary databases are created in the matching secondary pool when the failover group is configured correctly.

## Implementation choice

Use an **Azure Automation Account PowerShell runbook** because Safetrac already uses Automation Accounts with managed identity authentication for Azure SQL operations.

Runbook:
`scripts/automation/Sync-AeaFailoverPoolPlacement.ps1`

### Pool mapping

| ASE primary pool | AEA target pool |
|---|---|
| sql-paas-ase-safetrac-prd-pool | sql-paas-ase-safetrac-prd-pool |
| sql-paas-ase-safetrac-prd-pool2 | sql-paas-ase-safetrac-prd-pool2 |
| sql-paas-ase-boardtrac-prd-pool | sql-paas-ase-boardtrac-prd-pool |

## Detection model

The runbook is reconciliation-based. It reads all ASE production databases on each scheduled run. This catches a newly-created ASE database as soon as its corresponding AEA geo-secondary exists, without requiring an event subscription or any write access to ASE.

For each database:

1. Read the ASE database and its current elastic-pool name.
2. Read ASE failover-group membership.
3. Find the same-named AEA database.
4. Confirm an AEA-to-ASE replication link exists.
5. Calculate the AEA target pool from the explicit mapping.
6. If already correct, do nothing.
7. If incorrect, move only the AEA database to the target pool.
8. Re-read ASE to confirm its pool did not change.
9. Re-read failover groups to confirm membership is unchanged.
10. If validation fails, request rollback of the AEA database to its previous pool.

## Production safety controls

- Default execution is report-only. `-ApplyChanges` is required for a write.
- `-ApplyChanges` also requires an explicit `ChangeWindowStart` and `ChangeWindowEnd`.
- Friday, Saturday and Sunday are hard-blocked.
- The runbook rejects an AEA target equal to the ASE server.
- Databases not in a failover group are skipped.
- Missing AEA secondaries are skipped. The runbook does not create databases.
- Missing replication links are skipped.
- Failover-group membership is captured before the write and compared after the write.
- ASE placement is re-read after every AEA change.
- Rollback writes only to AEA.

## Identity and RBAC

Use a dedicated managed identity for ITP-233 rather than reusing a broad production identity.

Recommended scope:

- **ASE:** Reader at `ASE-RSG-PRD-APP` so the automation can inventory databases and failover groups but cannot change them.
- **AEA:** SQL DB Contributor scoped to the `sql-paas-aea-safetrac-prd` SQL server resource, or a narrower custom role containing only the required database read/write operations.

Do not grant SQL Server Contributor at subscription or resource-group scope.

Microsoft documents SQL DB Contributor as a database-management role and distinguishes it from SQL Server Contributor, which can manage SQL server resources.

## Change-window model

Recommended operational model:

### Continuous discovery

Schedule the runbook in report-only mode during normal business hours so it can identify pending AEA placement corrections without changing production.

### Controlled production correction

Use a separate Automation schedule or approved manual start for `-ApplyChanges` during the approved weekday change window.

Do not schedule production correction on Friday or weekends.

Before each production window:

1. Confirm application health.
2. Confirm SQL listener health.
3. Confirm no active failover or incident.
4. Run report-only mode and save the candidate list.
5. Select a small batch.
6. Capture the pre-change AEA pool and failover-group membership.

After each batch:

1. Confirm every target AEA database is in the expected pool.
2. Confirm ASE pool placement is unchanged.
3. Confirm failover-group membership is unchanged.
4. Confirm replication link still exists.
5. Check application and SQL listener health.
6. Continue only after the checkpoint passes.

## Rollback

For a failed correction, the runbook records the previous AEA pool and attempts to move the AEA database back to that pool.

Rollback does not:

- modify the ASE primary database;
- remove or re-add the database to a failover group;
- delete the database;
- fail over the database.

If automated rollback fails, stop the batch and perform the AEA-only rollback manually during the approved change window.

## Initial validation plan

1. Import the runbook into the Automation Account.
2. Enable the Automation Account managed identity.
3. Assign read-only access to ASE.
4. Assign AEA database write access at the narrowest practical scope.
5. Run report-only against a single known database with `-DatabaseName`.
6. Compare the generated target pool with the approved mapping.
7. Run report-only across the production server and export the candidate list.
8. During an approved weekday window, test one non-critical mismatched AEA database.
9. Validate placement, ASE placement, failover-group membership and replication.
10. Test rollback using the recorded previous AEA pool.
11. Only then enable the scheduled production correction window.

## Important limitation

The connected environment used for this implementation does not expose a direct Azure Resource Manager/Azure Automation deployment action. Therefore this change set prepares the runbook and deployment/validation design but does **not** create or enable an Azure production schedule, assign RBAC, or modify any SQL production resource.

That is intentional: the user's ASE production safety boundary remains intact until the controlled change window is explicitly approved.

## References

- Microsoft Azure SQL failover groups: https://learn.microsoft.com/en-us/azure/azure-sql/database/auto-failover-group-sql-db
- Microsoft Set-AzSqlDatabase: https://learn.microsoft.com/en-us/powershell/module/az.sql/set-azsqldatabase
- Microsoft Get-AzSqlDatabaseReplicationLink: https://learn.microsoft.com/en-us/powershell/module/az.sql/get-azsqldatabasereplicationlink
- Microsoft Azure built-in database roles: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/databases
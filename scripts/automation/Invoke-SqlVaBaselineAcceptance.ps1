<#
.SYNOPSIS
    Weekly automated "accept current findings as baseline" for Microsoft Defender for Cloud
    SQL Vulnerability Assessment (Express configuration), across every database on a SQL
    logical server (or Managed Instance / Synapse workspace).

.DESCRIPTION
    Reproduces, per database, exactly what clicking "Add all results as baseline" does on
    every failed VA rule for that database -- but in one API call per database instead of
    one click per rule per database. Uses the unified SQL Vulnerability Assessment REST API
    (api-version 2026-04-01-preview):
        POST .../providers/Microsoft.Security/sqlVulnerabilityAssessments/default/baselineRules
             ?api-version=2026-04-01-preview&databaseName=<db>
        Body: { "latestScan": true, "results": {} }

    Because Express configuration keeps recurring scans always active and applies new
    baselines WITHOUT requiring a re-scan, this runbook does NOT trigger scans itself -- it
    only reads each database's latest scan result and, if it has failures, baselines them.
    That keeps a 500+ database run fast (2 API calls per database instead of a full
    scan-and-poll cycle).

    Designed to run as an Azure Automation PowerShell 7.2 runbook under a System-Assigned
    Managed Identity (Connect-AzAccount -Identity). No Az.Sql / Az modules are required
    beyond Az.Accounts (for the token) since everything else is plain REST.

.PARAMETER ServerResourceId
    Full ARM resource ID of the SQL logical server / Managed Instance / Synapse workspace, e.g.
    /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Sql/servers/sql-paas-aea-safetrac-test

.PARAMETER ArmEndpoint
    ARM management endpoint. Default: https://management.azure.com

.PARAMETER IncludeMaster
    Include the 'master' system database in the run. Default: $false (most orgs only care
    about baselining user databases; master is usually managed separately).

.OUTPUTS
    Writes a per-database summary table to the job output (visible under the Automation
    Account -> Jobs -> Output tab) and throws a terminating error if ANY database failed to
    baseline, so a failed run shows up clearly (and can trigger Automation Account alerting).

.NOTES
    IMPORTANT -- read before scheduling this weekly:
    Baselining does not fix anything. It tells Defender for Cloud "this current state is
    expected," so any principal, permission, or setting present at the moment this runbook
    runs is marked as acceptable going forward -- including something that SHOULD have been
    flagged (e.g. an unexpected new db_owner). Because this script re-baselines ALL current
    failures every run, a genuinely new/anomalous finding introduced between runs will be
    silently accepted the next time this runs, with no human review.
    This is a reasonable trade-off ONLY if the set of expected owners/principals/permissions
    is already enforced elsewhere (e.g. templated per-tenant provisioning) so a VA "failure"
    here is just consistent-by-design noise rather than a real signal. If that's not the
    case, consider having the runbook alert on NEW findings instead of silently baselining
    everything.

    Prerequisites (Automation Account's system-assigned managed identity):
      - Reader, scoped to the target SQL server/instance
      - SQL Security Manager, scoped to the target SQL server/instance
    See ../verification/ and the repo README for the role-assignment commands.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ServerResourceId,

    [string] $ArmEndpoint = "https://management.azure.com",

    [bool] $IncludeMaster = $false
)

$ErrorActionPreference = "Stop"
$apiVersion = "2026-04-01-preview"
$ServerResourceId = $ServerResourceId.TrimStart("/")

Write-Output "=== SQL VA Baseline Acceptance Run ==="
Write-Output "Server resource: /$ServerResourceId"
Write-Output "Started (UTC)  : $([DateTime]::UtcNow.ToString('u'))"

# ---------------------------------------------------------------------------
# Auth: Automation Account System-Assigned Managed Identity
# ---------------------------------------------------------------------------
Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
$tokenObj = Get-AzAccessToken -ResourceUrl $ArmEndpoint
$token = $tokenObj.Token
if ($token -is [System.Security.SecureString]) {
    # Az.Accounts 3.x returns a SecureString by default
    $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
}
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

function Invoke-Api {
    param([string]$Method, [string]$Url, [string]$Body)
    $params = @{ Method = $Method; Uri = $Url; Headers = $headers; SkipHttpErrorCheck = $true }
    if ($Body) { $params.Body = $Body }
    $r = Invoke-WebRequest @params
    $parsed = try { $r.Content | ConvertFrom-Json } catch { $null }
    return @{ StatusCode = $r.StatusCode; Body = $parsed; Raw = $r.Content }
}

function Get-ErrorMessage {
    param($Response)
    if ($Response.Body.error.message) { return $Response.Body.error.message }
    if ($Response.Body.message)       { return $Response.Body.message }
    return $Response.Raw
}

# ---------------------------------------------------------------------------
# Step 1: Discover all databases on the server (handles pagination)
# ---------------------------------------------------------------------------
Write-Output "`nDiscovering databases..."
$databases = @()
$dbListUrl = "$ArmEndpoint/$ServerResourceId/databases?api-version=2021-02-01-preview"

while ($dbListUrl) {
    $r = Invoke-Api -Method GET -Url $dbListUrl
    if ($r.StatusCode -ne 200) {
        throw "Failed to list databases (HTTP $($r.StatusCode)): $(Get-ErrorMessage $r)"
    }
    $databases += @($r.Body.value | ForEach-Object { $_.name })
    $dbListUrl = $r.Body.nextLink
}

$databases = $databases | Where-Object { $_ -ne "master" -or $IncludeMaster } | Select-Object -Unique
Write-Output "Found $($databases.Count) database(s) to process."

# ---------------------------------------------------------------------------
# Step 2: For each database, check latest scan and baseline any failures
# ---------------------------------------------------------------------------
$opsBase = "$ArmEndpoint/$ServerResourceId/providers/Microsoft.Security/sqlVulnerabilityAssessments/default"
$summary = [System.Collections.Generic.List[object]]::new()
$i = 0

foreach ($db in $databases) {
    $i++
    $dbQuery = "&databaseName=$db"

    $scanUrl = "${opsBase}/scans/latest?api-version=${apiVersion}${dbQuery}"
    $scanResp = Invoke-Api -Method GET -Url $scanUrl

    if ($scanResp.StatusCode -ne 200) {
        $summary.Add([PSCustomObject]@{
            Database = $db; FailedBefore = "-"; Action = "SCAN FETCH FAILED"
            Detail   = "HTTP $($scanResp.StatusCode): $(Get-ErrorMessage $scanResp)"
        })
        continue
    }

    $failedCount = $scanResp.Body.properties.totalFailedRulesCount
    if (-not $failedCount -or $failedCount -eq 0) {
        $summary.Add([PSCustomObject]@{
            Database = $db; FailedBefore = 0; Action = "Skipped (no findings)"; Detail = "-"
        })
        continue
    }

    $addUrl = "${opsBase}/baselineRules?api-version=${apiVersion}${dbQuery}"
    $body = @{ latestScan = $true; results = @{} } | ConvertTo-Json -Compress
    $addResp = Invoke-Api -Method POST -Url $addUrl -Body $body

    if ($addResp.StatusCode -eq 200) {
        $baselinedCount = @($addResp.Body.value).Count
        $summary.Add([PSCustomObject]@{
            Database = $db; FailedBefore = $failedCount; Action = "Baselined"
            Detail   = "$baselinedCount rule(s) baselined"
        })
    } else {
        $summary.Add([PSCustomObject]@{
            Database = $db; FailedBefore = $failedCount; Action = "BASELINE FAILED"
            Detail   = "HTTP $($addResp.StatusCode): $(Get-ErrorMessage $addResp)"
        })
    }

    if ($i % 50 -eq 0) { Write-Output "  ...processed $i / $($databases.Count)" }
}

# ---------------------------------------------------------------------------
# Step 3: Report
# ---------------------------------------------------------------------------
Write-Output "`n=== Summary ==="
$summary | Format-Table -AutoSize | Out-String | Write-Output

$baselinedDbs = @($summary | Where-Object { $_.Action -eq "Baselined" })
$skippedDbs   = @($summary | Where-Object { $_.Action -like "Skipped*" })
$failedDbs    = @($summary | Where-Object { $_.Action -like "*FAILED*" })

Write-Output "Databases processed : $($databases.Count)"
Write-Output "Baselined this run  : $($baselinedDbs.Count)"
Write-Output "Already clean        : $($skippedDbs.Count)"
Write-Output "Failed               : $($failedDbs.Count)"
Write-Output "Finished (UTC)      : $([DateTime]::UtcNow.ToString('u'))"

if ($failedDbs.Count -gt 0) {
    # Non-zero exit / terminating error so the Automation job shows "Failed" and can alert
    throw "$($failedDbs.Count) database(s) failed to process. See summary above for details."
}

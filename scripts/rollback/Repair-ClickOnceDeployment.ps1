<#
.SYNOPSIS
    Clears ClickOnce cache/deployment metadata and re-registers the ClickOnce runtime — CHANGES LIVE STATE.

.DESCRIPTION
    From MOWINC0138201 (P1 — IFS Enterprise Explorer ClickOnce launch failures). Useful when
    a client is holding onto a stale manifest or deployment endpoint reference from before an
    infrastructure migration (e.g. an old Application Gateway IP baked into a cached manifest),
    or when ClickOnce's own runtime registration has gotten into a bad state.

    Clears: per-user ClickOnce cache (AppData\Local\Apps\2.0), the standard online app cache
    (via dfshim.dll), WinINet/IE cache, and ClickOnce deployment registry subscriptions.
    Re-registers dfshim.dll and the .application file association.

    Note from the original incident: this repair pass alone did not resolve the specific
    failure there -- the actual root cause turned out to be TLS registry state (see
    scripts/rollback/Set-TlsRegistryState.ps1 -Mode Reset). Run this first since it's
    lower-risk and commonly sufficient, but don't assume it's the fix if ClickOnce keeps
    failing after a clean run.

.PARAMETER SkipTlsReverify
    By default this script re-applies TLS 1.2 + SchUseStrongCrypto as part of the pass
    (matching the original remediation sequence). Pass this switch to skip that step if TLS
    state is already known-good or being managed separately via Set-TlsRegistryState.ps1.

.EXAMPLE
    .\Repair-ClickOnceDeployment.ps1

.EXAMPLE
    .\Repair-ClickOnceDeployment.ps1 -SkipTlsReverify

.NOTES
    Run as Administrator. No reboot required. If this doesn't resolve the issue, escalate to
    `sfc /scannow` + `dism /online /cleanup-image /restorehealth` (reboot required, bigger
    hammer, use only after this has been ruled out).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$SkipTlsReverify
)

Write-Host "=== ClickOnce Repair ===" -ForegroundColor Cyan
Write-Host "This script CHANGES LIVE STATE: clears ClickOnce/WinINet cache, removes deployment" -ForegroundColor Red
Write-Host "registry subscriptions, re-registers dfshim.dll, and (unless -SkipTlsReverify) sets TLS registry values." -ForegroundColor Red
$confirmation = Read-Host "Type YES to continue"
if ($confirmation -ne "YES") {
    Write-Host "Aborted -- no changes made." -ForegroundColor Yellow
    exit
}

if ($PSCmdlet.ShouldProcess("Local machine", "Stop ClickOnce processes and clear cache")) {
    Write-Host "1. Stopping ClickOnce processes..."
    Stop-Process -Name "dfsvc" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "dfshim" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "2. Clearing standard ClickOnce online app cache..."
    rundll32 dfshim.dll,CleanOnlineAppCache

    Write-Host "3. Clearing ClickOnce + Internet cache directories..."
    $cacheLocations = @(
        "$env:LOCALAPPDATA\Apps\2.0",
        "$env:LOCALAPPDATA\InetCache",
        "C:\ProgramData\Microsoft\Windows\Caches"
    )
    foreach ($location in $cacheLocations) {
        if (Test-Path $location) {
            Write-Host "  Clearing: $location"
            Remove-Item -Path "$location\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "4. Removing ClickOnce deployment registry subscriptions (current user)..."
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Deployment" /f 2>$null
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Installer" /f 2>$null

    Write-Host "5. Clearing WinINet cache (may hold stale SSL handshake state)..."
    RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255

    Write-Host "6. Re-registering ClickOnce runtime (dfshim.dll)..."
    $dfshimPath = "C:\Windows\System32\dfshim.dll"
    if (Test-Path $dfshimPath) {
        regsvcs.exe /c $dfshimPath
    } else {
        Write-Host "  dfshim.dll not found" -ForegroundColor Yellow
    }

    Write-Host "7. Re-associating .application file type..."
    reg add "HKCR\.application" /v "Content Type" /t REG_SZ /d "application/x-ms-application" /f
    reg add "HKCR\.application" /ve /t REG_SZ /d "application" /f

    if (-not $SkipTlsReverify) {
        Write-Host "8. Re-verifying TLS 1.2 configuration..."
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f
        reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f
    }

    Write-Host "9. Flushing DNS..."
    ipconfig /flushdns
}

Write-Host "`nRepair pass complete. Try launching ClickOnce now." -ForegroundColor Green
Write-Host "If it still fails, see scripts/rollback/Set-TlsRegistryState.ps1 -Mode Reset before escalating to sfc/DISM." -ForegroundColor Yellow

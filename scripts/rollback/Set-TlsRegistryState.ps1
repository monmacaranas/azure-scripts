<#
.SYNOPSIS
    Sets or resets explicit TLS 1.2 registry configuration on a Windows client — CHANGES LIVE STATE.

.DESCRIPTION
    Two modes, both from MOWINC0138201 (P1 — ClickOnce launch failures with
    "Could not create SSL/TLS secure channel"):

    -Mode Enable   Explicitly enables TLS 1.2 in SCHANNEL and sets SchUseStrongCrypto=1 for
                   .NET (32-bit and 64-bit). This is the standard fix for older Windows images
                   that predate TLS 1.2 defaults, and it DID resolve generic HTTPS/TLS
                   connectivity in the original incident.

    -Mode Reset    Removes explicit TLS registry overrides so Windows falls back to system
                   defaults. THIS WAS THE ACTUAL FIX in the original incident: -Mode Enable
                   looked successful (PowerShell/browser HTTPS tests passed) but ClickOnce
                   itself kept failing. A side-by-side diff of a working device vs. a failing
                   one showed the working device had NO explicit TLS registry entries at all —
                   the explicit TLS 1.0/1.1-disabled + TLS 1.2-enabled state was itself
                   breaking ClickOnce's internal TLS negotiation/fallback logic.

    Lesson: if -Mode Enable doesn't resolve a ClickOnce-specific failure (as opposed to
    general HTTPS failures), don't add more explicit registry state — try -Mode Reset instead.

.PARAMETER Mode
    'Enable' to explicitly turn on TLS 1.2, or 'Reset' to remove explicit overrides and
    restore system defaults.

.PARAMETER Reboot
    If specified, reboots automatically after applying the change (60 second delay).
    Otherwise the script prompts you to reboot manually — required for changes to take effect.

.EXAMPLE
    .\Set-TlsRegistryState.ps1 -Mode Enable -Reboot

.EXAMPLE
    .\Set-TlsRegistryState.ps1 -Mode Reset

.NOTES
    Run as Administrator. Take a System Restore point or registry backup first on a
    production device. Changes require a reboot to take effect.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Enable", "Reset")]
    [string]$Mode,

    [Parameter(Mandatory = $false)]
    [switch]$Reboot
)

$tls12Key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
$net64 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
$net32 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"

Write-Host "This script CHANGES LIVE REGISTRY STATE on this machine (Mode: $Mode)." -ForegroundColor Red
Write-Host "Take a System Restore point or registry backup first if this is a production device." -ForegroundColor Red
$confirmation = Read-Host "Type YES to continue"
if ($confirmation -ne "YES") {
    Write-Host "Aborted -- no changes made." -ForegroundColor Yellow
    exit
}

if ($Mode -eq "Enable") {
    Write-Host "=== Enabling explicit TLS 1.2 configuration ===" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Local machine", "Enable TLS 1.2 + SchUseStrongCrypto")) {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f
        reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f
        reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f
        Write-Host "Applied. If this is meant to fix a ClickOnce-specific failure (not just general HTTPS), verify ClickOnce works after reboot -- if it still fails, try -Mode Reset instead." -ForegroundColor Green
    }
}
elseif ($Mode -eq "Reset") {
    Write-Host "=== Removing explicit TLS overrides, restoring system defaults ===" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Local machine", "Remove explicit TLS 1.0/1.1/1.2 registry overrides")) {
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v Enabled /f 2>$null
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v Enabled /f 2>$null
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /f 2>$null
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v DisabledByDefault /f 2>$null
        Write-Host "Explicit TLS overrides removed. SchUseStrongCrypto left untouched intentionally -- the confirmed fix in the original incident did not require removing it." -ForegroundColor Green
        Write-Host "If ClickOnce still fails after this + a reboot, also try: reg delete `"$net64`" /v SchUseStrongCrypto /f  (and the 32-bit equivalent)" -ForegroundColor Yellow
    }
}

if ($Reboot) {
    Write-Host "`nRebooting in 60 seconds..." -ForegroundColor Yellow
    shutdown /r /t 60 /c "TLS registry state changed by Set-TlsRegistryState.ps1 -Mode $Mode"
} else {
    Write-Host "`nA reboot is required for this change to take effect. Run 'shutdown /r /t 0' when ready, or re-run with -Reboot." -ForegroundColor Yellow
}

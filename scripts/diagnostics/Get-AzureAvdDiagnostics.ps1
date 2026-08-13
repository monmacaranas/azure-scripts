<#
.SYNOPSIS
Collects common Azure Virtual Desktop host pool and session-host information.

.DESCRIPTION
Read-only diagnostic for AVD incidents involving unavailable session hosts, registration,
VM state and network configuration. Intended as a fast evidence collection step before
changing host pool, VM, NSG, DNS or routing settings.

SAFETY: READ-ONLY.

.REQUIREMENTS
Az.Accounts, Az.DesktopVirtualization, Az.Compute and Az.Network.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$HostPoolName
)

$ErrorActionPreference = 'Continue'
if (-not (Get-AzContext)) { throw 'No Azure context. Run Connect-AzAccount first.' }

Write-Host '=== Host pool ==='
Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $HostPoolName |
    Select-Object Name, Location, HostPoolType, LoadBalancerType, MaxSessionLimit,
        ValidationEnvironment, RegistrationInfoExpirationTime |
    Format-List

Write-Host "`n=== Session hosts ==="
$hosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName
$hosts | Select-Object Name, Status, AllowNewSession, Sessions, LastHeartBeat,
    AgentVersion, OsVersion, UpdateState | Format-Table -AutoSize

Write-Host "`n=== Related VM status (best effort) ==="
foreach ($host in $hosts) {
    $vmName = ($host.Name -split '/')[-1].Split('.')[0]
    try {
        Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -Status |
            Select-Object Name, Location, PowerState | Format-Table -AutoSize
    } catch {
        Write-Warning "VM '$vmName' was not found in resource group '$ResourceGroupName' or status could not be read."
    }
}

Write-Host "`nCompleted. No Azure resources were modified."

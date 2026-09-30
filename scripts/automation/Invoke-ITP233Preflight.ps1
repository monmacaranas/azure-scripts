# ITP-233 bootstrap / validation helper
# Run from an approved admin workstation or deployment pipeline. This script does NOT change ASE SQL resources.
[CmdletBinding()] param(
  [switch]$ApplyRbac,
  [switch]$RunDryRun,
  [string]$AutomationIdentityId='1b9555c1-e6dd-4e0d-88a1-3666dd007f64',
  [string]$PrimaryResourceGroup='ASE-RSG-PRD-APP',
  [string]$PrimaryServer='sql-paas-ase-safetrac-prd',
  [string]$SecondaryResourceGroup='aea-rsg-prd-app',
  [string]$SecondaryServer='sql-paas-aea-safetrac-prd',
  [string]$SubscriptionId=''
)
$ErrorActionPreference='Stop'

if(-not (Get-Command az -ErrorAction SilentlyContinue)){throw 'Azure CLI is required.'}
if($SubscriptionId){az account set --subscription $SubscriptionId}

Write-Host 'ITP-233 preflight: Azure account and resource verification'
az account show --output table
az sql server show --resource-group $PrimaryResourceGroup --name $PrimaryServer --query '{name:name,id:id}' --output table
az sql server show --resource-group $SecondaryResourceGroup --name $SecondaryServer --query '{name:name,id:id}' --output table

Write-Host 'Checking existing Automation identity:' $AutomationIdentityId
az ad sp show --id $AutomationIdentityId --query '{id:id,appId:appId,displayName:displayName}' --output table

if($ApplyRbac){
  Write-Warning 'RBAC application requested. This section intentionally requires explicit resource IDs and is not executed automatically by ITP-233.'
  throw 'Populate and review exact Automation Account resource ID and AEA SQL scope before applying RBAC.'
}

if($RunDryRun){
  Write-Host 'Dry-run must be executed from the Automation Account because the runbook uses managed identity authentication.'
  Write-Host 'Recommended parameters: -DatabaseName <candidate> with ApplyChanges omitted.'
  Write-Host 'Expected result: PLAN/OK/SKIP records only. No Azure write operation is issued.'
}

Write-Host 'Preflight complete. No ASE SQL placement or failover-group mutation was performed.'
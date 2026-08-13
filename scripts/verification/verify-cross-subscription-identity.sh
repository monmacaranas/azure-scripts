#!/usr/bin/env bash
#
# verify-cross-subscription-identity.sh
#
# Read-only verification for a cross-subscription Managed Identity setup, e.g. an App
# Service in the Corporate subscription reading/writing a Storage Account that lives in
# the Production subscription. Confirms the three things that most commonly go wrong:
#   1. The App Service's managed identity is actually enabled
#   2. The RBAC role assignment exists on the target resource (in the TARGET subscription)
#   3. The identity can actually authenticate against the target resource right now
#
# This makes no changes -- safe to run any time you need to sanity-check the setup.
#
# Usage:
#   ./verify-cross-subscription-identity.sh <corp-resource-group> <app-service-name> \
#       <prod-subscription-id> <prod-resource-group> <storage-account-name>
#
# Example:
#   ./verify-cross-subscription-identity.sh RG-CORP-APPS webapp-coursalator-prerelease \
#       66aa9f02-b332-42bc-b79e-eb84cdab5c10 ASE-RSG-PRD-APP saasesafetracassetspre

set -euo pipefail

CORP_RG="${1:?Usage: $0 <corp-rg> <app-service-name> <prod-sub-id> <prod-rg> <storage-account-name>}"
APP_NAME="${2:?Missing app service name}"
PROD_SUB="${3:?Missing production subscription id}"
PROD_RG="${4:?Missing production resource group}"
STORAGE_ACCOUNT="${5:?Missing storage account name}"

echo "=== 1. Managed Identity on $APP_NAME (Corporate subscription) ==="
az webapp identity show --resource-group "$CORP_RG" --name "$APP_NAME" \
  --query "{type:type, principalId:principalId}" -o table

echo ""
echo "=== 2. Role assignment on $STORAGE_ACCOUNT (Production subscription) ==="
az role assignment list \
  --scope "/subscriptions/${PROD_SUB}/resourceGroups/${PROD_RG}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}" \
  --query "[].{principal:principalName, role:roleDefinitionName}" -o table

echo ""
echo "=== 3. Live auth test against the storage account ==="
echo "(uses your own logged-in identity, not the app's -- confirms the account/network is reachable)"
az storage blob list --account-name "$STORAGE_ACCOUNT" --auth-mode login -o table || \
  echo "Note: a failure here can also just mean 'no blobs' or 'your own account lacks this role' -- it's a reachability sanity check, not a substitute for testing the app itself."

echo ""
echo "If step 1 shows no principalId, the identity isn't enabled -- fix that first."
echo "If step 2 shows no matching role assignment, that's almost always the actual cause"
echo "of a 403/AuthenticationFailedException from the app."

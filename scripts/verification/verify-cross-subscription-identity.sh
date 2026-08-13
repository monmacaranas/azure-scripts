#!/usr/bin/env bash
#
# verify-cross-subscription-identity.sh
#
# Read-only verification for cross-subscription Managed Identity + Storage RBAC.
# Confirms identity state, target-scope RBAC and basic storage reachability.
#
# Usage:
#   ./verify-cross-subscription-identity.sh <source-rg> <app-name> \
#       <target-subscription-id> <target-rg> <storage-account-name>
#
# Example:
#   ./verify-cross-subscription-identity.sh '<source-rg>' '<app-name>' \
#       '<target-subscription-id>' '<target-rg>' '<storage-account-name>'
#
# SAFETY: READ-ONLY. No tenant IDs, subscription IDs or resource names are hardcoded.

set -euo pipefail

SOURCE_RG="${1:?Usage: $0 <source-rg> <app-name> <target-sub-id> <target-rg> <storage-account-name>}"
APP_NAME="${2:?Missing app service name}"
TARGET_SUB="${3:?Missing target subscription id}"
TARGET_RG="${4:?Missing target resource group}"
STORAGE_ACCOUNT="${5:?Missing storage account name}"

echo "=== 1. Managed Identity on $APP_NAME ==="
az webapp identity show --resource-group "$SOURCE_RG" --name "$APP_NAME" \
  --query "{type:type, principalId:principalId}" -o table

echo ""
echo "=== 2. Role assignments on target storage account ==="
az role assignment list \
  --scope "/subscriptions/${TARGET_SUB}/resourceGroups/${TARGET_RG}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}" \
  --query "[].{principal:principalName, role:roleDefinitionName}" -o table

echo ""
echo "=== 3. Basic storage reachability/auth sanity check ==="
az storage blob list --account-name "$STORAGE_ACCOUNT" --auth-mode login -o table || \
  echo "The current operator identity may lack blob data access; validate the app identity separately."

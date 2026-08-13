#!/usr/bin/env bash
#
# rollback-managed-identity-storage-auth.sh
#
# Emergency rollback for a Managed-Identity-based storage auth migration (Coursalator
# pattern): re-opens blob public access and removes the app's managed identity, restoring
# the pre-migration state so a previous connection-string-based deployment works again.
#
# THIS SCRIPT MAKES LIVE CHANGES. Read every command before running -- do not pipe this
# into a shell blind. Intended to be run interactively, one section at a time, by whoever
# holds write access, only after a real incident (uploads broken in production).
#
# Usage (do not just execute top to bottom without reading -- see comments per step):
#   ./rollback-managed-identity-storage-auth.sh <storage-rg> <storage-account-name> \
#       <app-rg> <app-service-name>

set -euo pipefail

STORAGE_RG="${1:?Usage: $0 <storage-rg> <storage-account-name> <app-rg> <app-service-name>}"
STORAGE_ACCOUNT="${2:?Missing storage account name}"
APP_RG="${3:?Missing app resource group}"
APP_NAME="${4:?Missing app service name}"

echo "About to roll back Managed Identity storage auth for:"
echo "  Storage account : $STORAGE_ACCOUNT (RG: $STORAGE_RG)"
echo "  App service     : $APP_NAME (RG: $APP_RG)"
read -r -p "Type 'rollback' to continue: " CONFIRM
if [[ "$CONFIRM" != "rollback" ]]; then
  echo "Aborted -- no changes made."
  exit 1
fi

echo ""
echo "=== Step 1: Re-enable blob public access (temporary safety net) ==="
az storage account update \
  --resource-group "$STORAGE_RG" \
  --name "$STORAGE_ACCOUNT" \
  --allow-blob-public-access true

echo ""
echo "=== Step 2: Remove the App Service's managed identity ==="
echo "(only do this if the previous connection-string-based code is also being redeployed --"
echo " removing the identity without reverting the code will just break auth a different way)"
az webapp identity remove --resource-group "$APP_RG" --name "$APP_NAME"

echo ""
echo "Rollback commands complete. Remaining manual steps:"
echo "  1. Redeploy the previous (connection-string) build via your CI/CD pipeline, or:"
echo "     git revert <managed-identity-commit> && git push origin <branch>"
echo "  2. Confirm the storage account key / connection string is present in Key Vault or config."
echo "  3. Verify uploads work again from the app UI."
echo "  4. Once confirmed, decide whether to leave the RBAC role assignment in place or remove it"
echo "     (removing it is optional cleanup, not required for the rollback to take effect)."

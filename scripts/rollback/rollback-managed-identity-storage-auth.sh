#!/usr/bin/env bash
#
# Emergency rollback for a Managed-Identity-based storage authentication migration.
# Re-opens blob public access and removes the App Service managed identity so a previous
# connection-string-based deployment can be restored if that is the approved rollback.
#
# THIS SCRIPT MAKES LIVE CHANGES. Review every command before execution.
# No tenant IDs, subscription IDs, resource names, credentials or secrets are hardcoded.
#
# Usage:
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

echo "=== Step 1: Re-enable blob public access ==="
az storage account update --resource-group "$STORAGE_RG" --name "$STORAGE_ACCOUNT" --allow-blob-public-access true

echo "=== Step 2: Remove the App Service managed identity ==="
az webapp identity remove --resource-group "$APP_RG" --name "$APP_NAME"

echo "Rollback commands complete. Redeploy the approved previous application build and verify service health."

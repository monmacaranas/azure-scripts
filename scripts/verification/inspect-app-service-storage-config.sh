#!/usr/bin/env bash
#
# Read-only sweep of an App Service's storage-related configuration.
# Usage:
#   ./inspect-app-service-storage-config.sh <resource-group> <app-service-name>
# Example:
#   ./inspect-app-service-storage-config.sh '<resource-group>' '<app-service-name>'

set -euo pipefail

RG="${1:?Usage: $0 <resource-group> <app-service-name>}"
APP_NAME="${2:?Missing app service name}"

echo "=== Outbound IP addresses ==="
az webapp show --resource-group "$RG" --name "$APP_NAME" --query "outboundIpAddresses" -o tsv

echo ""
echo "=== VNet integration state ==="
az webapp vnet-integration list --resource-group "$RG" --name "$APP_NAME" -o table

echo ""
echo "=== App settings mentioning storage/key vault (names only) ==="
az webapp config appsettings list --resource-group "$RG" --name "$APP_NAME" \
  --query "[?contains(name, 'Storage') || contains(name, 'KeyVault') || contains(name, 'Vault')].{name:name}" -o table

echo ""
echo "=== VNets visible in this resource group ==="
az network vnet list --resource-group "$RG" --query "[].name" -o tsv

#!/usr/bin/env bash
#
# inspect-app-service-storage-config.sh
#
# Read-only sweep of an App Service's storage-related configuration -- useful as a first
# pass when a "can't reach storage" ticket comes in, before assuming a network cause.
# Surfaces: outbound IPs (needed for firewall allow-lists), VNet integration state,
# app settings that reference storage/Key Vault, and current VNet peerings.
#
# Usage:
#   ./inspect-app-service-storage-config.sh <resource-group> <app-service-name>
#
# Example:
#   ./inspect-app-service-storage-config.sh RG-DEV-ST-BT webapp-coursalator-prerelease

set -euo pipefail

RG="${1:?Usage: $0 <resource-group> <app-service-name>}"
APP_NAME="${2:?Missing app service name}"

echo "=== Outbound IP addresses (for storage/firewall allow-lists) ==="
az webapp show --resource-group "$RG" --name "$APP_NAME" --query "outboundIpAddresses" -o tsv

echo ""
echo "=== VNet integration state ==="
az webapp vnet-integration list --resource-group "$RG" --name "$APP_NAME" -o table

echo ""
echo "=== App settings mentioning storage/key vault (values redacted by az where sensitive) ==="
az webapp config appsettings list --resource-group "$RG" --name "$APP_NAME" \
  --query "[?contains(name, 'Storage') || contains(name, 'KeyVault') || contains(name, 'Vault')].{name:name}" -o table

echo ""
echo "=== VNet peerings visible from this resource group's VNet(s) ==="
echo "(run manually per VNet name if there's more than one in this RG -- see repo README)"
az network vnet list --resource-group "$RG" --query "[].name" -o tsv

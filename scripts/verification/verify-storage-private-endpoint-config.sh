#!/usr/bin/env bash
#
# verify-storage-private-endpoint-config.sh
#
# Read-only Azure CLI check of a storage account's network posture and (optionally) an
# App Service's path to it, for "works in prod, 403s in test" / "can't reach storage
# account" symptoms against private-endpoint-only accounts.
#
# Background: this distinguishes two different failure modes that look similar but need
# different fixes -- an App Service reaching a private-endpoint storage account over the
# wrong path (DNS/VNet-integration problem, fixable) vs. a client entirely outside the VNet
# (e.g. a developer laptop on home Wi-Fi) with no path to a private endpoint at all
# (access-pattern decision -- VPN/Bastion/allow-list -- not a config bug).
#
# Requires: Azure CLI, logged in (`az login`) with read access to the target subscription.
#
# Usage:
#   ./verify-storage-private-endpoint-config.sh <storage-account-name> <resource-group> [webapp-name]

set -euo pipefail

STORAGE_ACCOUNT="${1:?Usage: $0 <storage-account-name> <resource-group> [webapp-name]}"
RESOURCE_GROUP="${2:?Usage: $0 <storage-account-name> <resource-group> [webapp-name]}"
WEBAPP_NAME="${3:-}"

echo "=== 1. Storage account network posture ==="
az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" \
  --query "{publicNetworkAccess:publicNetworkAccess, defaultAction:networkRuleSet.defaultAction}" \
  -o table

echo ""
echo "=== 2. Private endpoint connection status (must be 'Approved') ==="
az network private-endpoint-connection list --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" --type Microsoft.Storage/storageAccounts -o table

if [[ -n "$WEBAPP_NAME" ]]; then
  echo ""
  echo "=== 3. App Service VNet integration ==="
  az webapp vnet-integration list --name "$WEBAPP_NAME" --resource-group "$RESOURCE_GROUP" -o table

  echo ""
  echo "=== 4. App Service route-all setting (must be true, or storage traffic bypasses the private endpoint entirely) ==="
  az webapp config show --name "$WEBAPP_NAME" --resource-group "$RESOURCE_GROUP" \
    --query "vnetRouteAllEnabled" -o tsv
fi

echo ""
echo "=== Interpretation notes ==="
cat <<'EOF'
- publicNetworkAccess: Disabled  -> no IP allow-list will help any caller outside the VNet.
  Access must come through the private endpoint (VPN, Bastion/jump box), or the account's
  network mode needs to change as a deliberate team decision -- not a one-off firewall rule.
- No VNet integration on the App Service -> it has no path to the private endpoint and is
  going out over the public internet, landing on the storage firewall. Most common cause of
  this exact symptom.
- VNet integration present but vnetRouteAllEnabled=false (or legacy WEBSITE_VNET_ROUTE_ALL
  unset) -> only RFC1918-destined traffic routes through the VNet; storage's public FQDN
  still resolves publicly and bypasses the private endpoint.
- If DNS is the suspected next layer: from Kudu/SSH on the App Service, run
  `nameresolver <account>.blob.core.windows.net` -- should return a 10.x/172.x/192.168.x
  address, not a public Azure Storage IP. If public, check the Private DNS Zone
  (privatelink.blob.core.windows.net or the relevant service suffix) is linked to the
  correct VNet.
EOF

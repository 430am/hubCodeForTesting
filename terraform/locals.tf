locals {
  # Naming token: explicit application_name when set, otherwise a stable random_pet.
  naming_token         = var.application_name != "" ? var.application_name : random_pet.naming.id
  naming_token_compact = replace(local.naming_token, "-", "")

  # Subnet layout, carved out of the first /16 in var.vnet_address_space.
  # AzureFirewallSubnet  -> 10.0.0.0/26   (Azure requires the exact name)
  # AzureBastionSubnet   -> 10.0.0.64/26  (Azure requires the exact name, /26 minimum)
  subnets = {
    AzureFirewallSubnet = cidrsubnet(var.vnet_address_space[0], 10, 0)
    AzureBastionSubnet  = cidrsubnet(var.vnet_address_space[0], 10, 1)
  }

  # privatelink.* zones the spoke stack expects to find in a single hub RG.
  # Order is preserved purely for readable plan output.
  private_dns_zones = [
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.dfs.core.windows.net",
    "privatelink.monitor.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
  ]

  tags = merge(var.tags, {
    application = local.naming_token
  })
}

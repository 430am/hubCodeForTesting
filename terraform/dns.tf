resource "azurerm_private_dns_zone" "hub" {
  for_each = toset(local.private_dns_zones)

  name                = each.value
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.tags
}

# Link the hub VNet to every zone so PEs created in the hub itself
# (none today, but future hub-side workloads) resolve correctly.
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = azurerm_private_dns_zone.hub

  name                  = "${local.naming_token}-hub-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.tags
}

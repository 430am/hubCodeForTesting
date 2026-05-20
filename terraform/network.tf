resource "azurerm_virtual_network" "hub" {
  name                = "${local.naming_token}-hub-vnet"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "hub" {
  for_each = local.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

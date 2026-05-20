resource "azurerm_log_analytics_workspace" "hub" {
  name                = "${local.naming_token}-hub-law"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
  tags                = local.tags
}

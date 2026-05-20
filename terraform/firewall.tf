# Azure Firewall (Standard SKU) with a permissive lab egress policy.
# Created only when var.deploy_firewall = true.

resource "azurerm_public_ip" "firewall" {
  count = var.deploy_firewall ? 1 : 0

  name                = "${local.naming_token}-hub-afw-pip"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall_policy" "hub" {
  count = var.deploy_firewall ? 1 : 0

  name                = "${local.naming_token}-hub-afw-policy"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = local.tags
}

# Single permissive network rule collection - this is a lab landing zone, not
# a production egress policy. Lock this down before going to production.
resource "azurerm_firewall_policy_rule_collection_group" "hub" {
  count = var.deploy_firewall ? 1 : 0

  name               = "${local.naming_token}-hub-afw-default"
  firewall_policy_id = azurerm_firewall_policy.hub[0].id
  priority           = 200

  network_rule_collection {
    name     = "allow-spoke-egress"
    priority = 1000
    action   = "Allow"

    rule {
      name                  = "any-any"
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["TCP", "UDP", "ICMP"]
    }
  }
}

resource "azurerm_firewall" "hub" {
  count = var.deploy_firewall ? 1 : 0

  name                = "${local.naming_token}-hub-afw"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub[0].id
  tags                = local.tags

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  depends_on = [azurerm_firewall_policy_rule_collection_group.hub]
}

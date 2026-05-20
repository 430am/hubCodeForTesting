resource "azurerm_public_ip" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                = "${local.naming_token}-hub-bas-pip"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# Standard SKU with tunneling enabled so spoke operators can `ssh -o ProxyCommand`
# through this Bastion to private VMs in peered spoke VNets.
resource "azurerm_bastion_host" "hub" {
  count = var.deploy_bastion ? 1 : 0

  name                = "${local.naming_token}-hub-bas"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tunneling_enabled   = true
  tags                = local.tags

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

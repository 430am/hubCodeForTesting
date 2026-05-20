resource "random_pet" "naming" {
  length = 2
}

resource "azurerm_resource_group" "hub" {
  name     = "${local.naming_token}-hub-rg"
  location = var.location
  tags     = local.tags
}

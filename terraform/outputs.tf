data "azurerm_subscription" "current" {}

output "hub_resource_group_name" {
  description = "Name of the hub resource group."
  value       = azurerm_resource_group.hub.name
}

output "hub_virtual_network_id" {
  description = "Resource ID of the hub VNet. Feeds spoke `var.hub.virtual_network.id`."
  value       = azurerm_virtual_network.hub.id
}

output "hub_subscription_id" {
  description = "Subscription the hub is deployed in. Feeds spoke `var.hub.subscription_id`."
  value       = data.azurerm_subscription.current.subscription_id
}

output "hub_private_dns_zones_resource_group_name" {
  description = "RG holding the privatelink.* zones. Feeds spoke `var.hub.private_dns_zones.resource_group_name`."
  value       = azurerm_resource_group.hub.name
}

output "hub_log_analytics_workspace_id" {
  description = "Central LAW resource ID. Feeds spoke `var.hub.monitoring.log_analytics_workspace_id`."
  value       = azurerm_log_analytics_workspace.hub.id
}

output "hub_firewall_private_ip" {
  description = "Azure Firewall private IP, or null when var.deploy_firewall = false. Feeds spoke `var.hub.egress.firewall_private_ip`."
  value       = var.deploy_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}

output "hub_bastion_host_id" {
  description = "Shared Bastion resource ID, or null when var.deploy_bastion = false. Feeds spoke `var.hub.bastion_host_id`."
  value       = var.deploy_bastion ? azurerm_bastion_host.hub[0].id : null
}

# Ready-to-paste snippet for the spoke's tfvars file. Copy the value of this
# output (terraform output -raw spoke_tfvars_snippet) into your spoke .tfvars.
output "spoke_tfvars_snippet" {
  description = "HCL block to paste into the spoke's tfvars file as `hub = { ... }`."
  value       = <<-EOT
    deployment_mode = "spoke"

    hub = {
      subscription_id = "${data.azurerm_subscription.current.subscription_id}"

      virtual_network = {
        id = "${azurerm_virtual_network.hub.id}"
      }

      egress = {
        mode                = "${var.deploy_firewall ? "firewall" : "policy"}"
        firewall_private_ip = ${var.deploy_firewall ? "\"${azurerm_firewall.hub[0].ip_configuration[0].private_ip_address}\"" : "null"}
      }

      private_dns_zones = {
        resource_group_name = "${azurerm_resource_group.hub.name}"
      }

      monitoring = {
        log_analytics_workspace_id = "${azurerm_log_analytics_workspace.hub.id}"
      }

      bastion_host_id = ${var.deploy_bastion ? "\"${azurerm_bastion_host.hub[0].id}\"" : "null"}
    }
  EOT
}

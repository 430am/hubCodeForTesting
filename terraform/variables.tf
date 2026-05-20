variable "application_name" {
  description = <<-EOT
    Product / application name used as the leading token in every resource
    name (`<application_name>-<abbrev>...`). Lowercase letters, numbers and
    hyphens only; 2-20 chars. Leave empty to fall back to a `random_pet`
    value (convenient for throwaway lab hubs).
  EOT
  type        = string
  default     = "hub"

  validation {
    condition     = var.application_name == "" || can(regex("^[a-z][a-z0-9-]{1,19}$", var.application_name))
    error_message = "application_name must be empty or 2-20 chars of lowercase letters/numbers/hyphens, starting with a letter."
  }
}

variable "location" {
  description = "The Azure region to deploy hub resources in."
  type        = string
  default     = "southcentralus"
}

variable "vnet_address_space" {
  description = <<-EOT
    Address space for the hub VNet. Must not overlap any spoke VNet that
    will peer in (the spoke stack defaults to 10.150.0.0/16).
  EOT
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "deploy_firewall" {
  description = <<-EOT
    When true, deploy an Azure Firewall (Standard SKU) in AzureFirewallSubnet
    with a permissive lab egress policy. Spokes can then set
    `hub.egress.mode = "firewall"` and point at `firewall_private_ip` output.
    When false, spokes must rely on Azure Policy-attached UDRs
    (`hub.egress.mode = "policy"`).
  EOT
  type        = bool
  default     = true
}

variable "deploy_bastion" {
  description = <<-EOT
    When true, deploy a shared Azure Bastion (Standard SKU, tunneling enabled)
    in AzureBastionSubnet. The Bastion host ID is surfaced via outputs so
    spokes can advertise it to operators via `var.hub.bastion_host_id`.
  EOT
  type        = bool
  default     = false
}

variable "log_analytics_sku" {
  description = "SKU for the central Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retention in days for the central Log Analytics workspace."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to every hub resource."
  type        = map(string)
  default = {
    managed_by = "terraform"
    role       = "hub"
  }
}

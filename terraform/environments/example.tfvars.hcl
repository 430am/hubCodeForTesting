# Example tfvars for the hub landing zone.
# Copy to local.tfvars.hcl and edit, then:
#   terraform apply -var-file=environments/local.tfvars.hcl

application_name = "hub"
location         = "southcentralus"

# Must not overlap any spoke VNet (spoke defaults to 10.150.0.0/16).
vnet_address_space = ["10.0.0.0/16"]

# Toggle the two big-ticket items.
deploy_firewall = true
deploy_bastion  = false

tags = {
  managed_by = "terraform"
  role       = "hub"
  owner      = "platform-team"
}

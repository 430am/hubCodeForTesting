# hub landing zone (Terraform)

Minimal Azure hub landing zone designed to be consumed by the spoke stack at
[430am/cyclecloud_as_code @ feat/hub-spoke-landing-zone](https://github.com/430am/cyclecloud_as_code/tree/feat/hub-spoke-landing-zone)
when it runs in `deployment_mode = "spoke"`.

The hub is intentionally small. It owns only what the spoke is contractually
required to consume from a hub, nothing more:

| Resource | Purpose | Toggle |
|---|---|---|
| Resource group | Holds every hub resource (incl. the DNS zones) | always |
| VNet + `AzureFirewallSubnet` / `AzureBastionSubnet` | Peering target for spokes | always |
| 9 `privatelink.*` private DNS zones | Central name resolution for spoke PEs | always |
| Log Analytics workspace | Central diagnostics / AMPLS scope target | always |
| Azure Firewall (Standard) + permissive lab policy | Egress for `hub.egress.mode = "firewall"` spokes | `var.deploy_firewall` |
| Azure Bastion (Standard, tunneling) | Shared break-glass jump host | `var.deploy_bastion` |

Spoke-side `var.hub` fields are mapped to outputs from this stack — see [terraform/outputs.tf](terraform/outputs.tf).

## Layout

```
terraform/
  versions.tf            terraform + provider pins (azurerm ~> 4.73)
  providers.tf           default azurerm provider
  variables.tf           inputs (location, vnet_address_space, toggles, tags)
  locals.tf              naming token, subnet CIDR math, DNS zone list
  main.tf                random_pet + resource group
  network.tf             VNet + AzureFirewallSubnet + AzureBastionSubnet
  firewall.tf            Azure Firewall + policy (count = var.deploy_firewall)
  bastion.tf             Azure Bastion + PIP   (count = var.deploy_bastion)
  dns.tf                 9 privatelink.* zones + hub-VNet links
  monitoring.tf          Log Analytics workspace
  outputs.tf             individual outputs + `spoke_tfvars_snippet`
  environments/
    example.tfvars.hcl   copy to local.tfvars.hcl and edit
```

## Quickstart

```bash
cd terraform
cp environments/example.tfvars.hcl environments/local.tfvars.hcl
$EDITOR environments/local.tfvars.hcl

export ARM_SUBSCRIPTION_ID=<hub-sub-id>
az login

terraform init
terraform apply -var-file=environments/local.tfvars.hcl
```

## Wiring a spoke to this hub

After `terraform apply` completes, paste the rendered snippet straight into the
spoke's tfvars file:

```bash
terraform output -raw spoke_tfvars_snippet >> /path/to/spoke/terraform/environments/myspoke.tfvars.hcl
```

That writes a block of the form:

```hcl
deployment_mode = "spoke"

hub = {
  subscription_id = "<hub-sub>"
  virtual_network = { id = "<hub-vnet-id>" }
  egress = {
    mode                = "firewall"    # or "policy" if var.deploy_firewall = false
    firewall_private_ip = "10.0.0.4"    # null when egress.mode = "policy"
  }
  private_dns_zones = { resource_group_name = "<hub>-hub-rg" }
  monitoring        = { log_analytics_workspace_id = "<law-id>" }
  bastion_host_id   = null               # or "<bastion-id>" when var.deploy_bastion = true
}
```

The spoke creates the spoke→hub peering itself and uses its aliased
`azurerm.hub` provider to create the hub→spoke peering and the per-zone VNet
links in the hub subscription. Required hub-side RBAC for the principal
running the spoke stack:

- `Network Contributor` on the hub VNet
- `Private DNS Zone Contributor` on the hub DNS RG
- `Monitoring Contributor` on the hub Log Analytics workspace

## Toggles

| Variable | Default | Effect |
|---|---|---|
| `deploy_firewall` | `true` | Spokes can use `hub.egress.mode = "firewall"`; set to `false` and spokes must use `"policy"` (Azure Policy-attached UDRs). |
| `deploy_bastion`  | `false` | Surface a shared Bastion via `hub.bastion_host_id` for spoke operators. Spokes can still deploy their own per-spoke Bastion for break-glass. |
| `vnet_address_space` | `["10.0.0.0/16"]` | Must not overlap any spoke VNet (spoke default is `10.150.0.0/16`). |

## Scope / non-goals

This is a lab landing zone. Specifically out of scope:

- Firewall egress is currently `*:* allow` on TCP/UDP/ICMP — replace with scoped rules before any non-lab use.
- No DDoS Standard plan, no NSG flow logs, no AMPLS at the hub layer (the spoke creates its own AMPLS scoping this LAW).
- No on-prem / ExpressRoute / VPN gateway.
- No identity-tier resources (assumed pre-existing in the tenant, matching Mission Landing Zone's tier-0 boundary).

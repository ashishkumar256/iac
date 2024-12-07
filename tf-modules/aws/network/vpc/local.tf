locals {
  flattened_public_subnets = merge([
    for az, details in var.subnets : {
      for index, cidr_value in lookup(details, "public", []) :
      format("%s-%02d", az, index + 1) => {
        az   = az
        cidr = cidr_value
      }
    }
  ]...)

  flattened_protected_subnets = merge([
    for az, details in var.subnets : {
      for index, cidr_value in lookup(details, "protected", []) :
      format("%s-%02d", az, index + 1) => {
        az   = az
        cidr = cidr_value
      }
    }
  ]...)

  flattened_private_subnets = merge([
    for az, details in var.subnets : {
      for index, cidr_value in lookup(details, "private", []) :
      format("%s-%02d", az, index + 1) => {
        az   = az
        cidr = cidr_value
      }
    }
  ]...)

  all_additional_subnets = flatten([
    for cidr_name, cidr_block in var.additional_cidr : [
      for az, subnets in cidr_block.subnets : [
        for type, cidrs in subnets : [
          for index, cidr in cidrs : merge({
            cidr_name = cidr_name,
            az        = az,
            type      = type,
            index     = index,
            cidr      = cidr
            },
            # Only add dedicated_nat and nat_az if the subnet is protected and NAT_GW exists
            (
              type == "protected" && lookup(cidr_block, "NAT_GW", null) != null
              ? {
                dedicated_nat = true,
                # Check NAT_GW.HA supports conditional check on null-safety
                nat_az = (lookup(cidr_block.NAT_GW, "HA", false) ? az : lookup(cidr_block.NAT_GW, "SingleAZ", az))
              }
              : {}
          ))
        ]
      ]
    ]
  ])

  public_subnet_map = { for subnet in local.all_additional_subnets :
  "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet if subnet.type == "public" }

  private_subnet_map = { for subnet in local.all_additional_subnets :
  "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet if subnet.type == "private" }

  protected_subnet_map = { for subnet in local.all_additional_subnets :
  "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet if subnet.type == "protected" }

  protected_subnet_map_without_dedicated_nat_gw = {
    for key, subnet in local.protected_subnet_map :
    key => subnet
    if lookup(subnet, "dedicated_nat", "false") != "true"
  }

  protected_subnet_map_with_dedicated_nat_gw = {
    for key, subnet in local.protected_subnet_map :
    key => subnet
    if lookup(subnet, "dedicated_nat", "false") == "true"
  }

  az_belongs_to_dedicated_nat_gw = [
    for key, value in {
      for subnet in local.protected_subnet_map_with_dedicated_nat_gw :
      "${subnet.cidr_name}-${subnet.nat_az}" => subnet...
      if subnet.az == subnet.nat_az
    } : value[0]
  ]

  az_belongs_to_protected_additional_route_table = [
    for subnet in local.protected_subnet_map_with_dedicated_nat_gw :
      subnet if subnet.index == 0
  ]
}
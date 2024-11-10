# This locals block is for framing aws_subnets with type public, protected & private
locals {
  # Flatten the subnet definitions into single maps with composite keys for each type
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
}

# This locals block is for framing additional aws_subnets with type public, protected & private
locals {
  all_additional_subnets = flatten([
    for cidr_name, cidr_block in var.additional_cidr : [
      for az, subnets in cidr_block.subnets : [
        for type, cidrs in subnets : [
          for index, cidr in cidrs : {
            cidr_name = cidr_name
            az        = az
            type      = type
            index     = index
            cidr      = cidr
          }
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

  protected_subnet_map_with_self_nat_gw = {
    for subnet in local.all_additional_subnets :
    "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet
    if subnet.type == "protected" && lookup(var.additional_cidr[subnet.cidr_name], "NAT_GW", { self = false }).self
  }

  protected_subnet_map_without_self_nat_gw = {
    for subnet in local.all_additional_subnets :
    "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet
    if subnet.type == "protected" && !lookup(var.additional_cidr[subnet.cidr_name], "NAT_GW", { self = false }).self
  }

  az_in_protected_subnet_map_with_self_nat_gw = distinct([
    for subnet in local.protected_subnet_map_with_self_nat_gw : subnet.az
  ])

  az_belongs_to_dedicated_nat = flatten([
    for cidr_name, cidr_data in var.additional_cidr : [
      for az in cidr_data.NAT_GW.HA ? local.az_in_protected_subnet_map_with_self_nat_gw : [cidr_data.NAT_GW.Preffered_data_AZ] : {
        "cidr_name" = cidr_name
        "az"        = az
      }
    ]
  ])

  #   eip_azs = toset([
  #     for subnet in local.all_additional_subnets :
  #     "${subnet.cidr_name}-${local.additional_cidr[subnet.cidr_name].NAT_GW.HA ? subnet.az : local.additional_cidr[subnet.cidr_name].NAT_GW.Preffered_data_AZ}"
  #     if subnet.type == "protected" && local.additional_cidr[subnet.cidr_name].NAT_GW.self
  #   ])
}




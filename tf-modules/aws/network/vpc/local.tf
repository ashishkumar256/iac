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
# locals {
#   all_additional_subnets = flatten([
#     for cidr_name, cidr_block in var.additional_cidr : [
#       for az, subnets in cidr_block.subnets : [
#         for type, cidrs in subnets : [
#           for index, cidr in cidrs : {
#             cidr_name = cidr_name
#             az        = az
#             type      = type
#             index     = index
#             cidr      = cidr
#           }
#         ]
#       ]
#     ]
#   ])

#   public_subnet_map = { for subnet in local.all_additional_subnets :
#   "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet if subnet.type == "public" }

#   private_subnet_map = { for subnet in local.all_additional_subnets :
#   "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet if subnet.type == "private" }

#   protected_subnet_map = { for subnet in local.all_additional_subnets :
#   "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet if subnet.type == "protected" }

#   # protected_subnet_map_with_self_nat_gw = {
#   #   for subnet in local.all_additional_subnets :
#   #   "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet
#   #   if subnet.type == "protected" && lookup(var.additional_cidr[subnet.cidr_name], "NAT_GW", { self = false }).self
#   # }

#   protected_subnet_map_with_self_nat_gw = {
#     for subnet in local.all_additional_subnets :
#     "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet
#     if subnet.type == "protected" &&
#        # Safely lookup 'NAT_GW' and then 'self' within it, defaulting to false if 'self' is not found.
#        lookup(lookup(var.additional_cidr[subnet.cidr_name], "NAT_GW", {}), "self", false)
#   }

#   # protected_subnet_map_without_self_nat_gw = {
#   #   for subnet in local.all_additional_subnets :
#   #   "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet
#   #   if subnet.type == "protected" && !lookup(var.additional_cidr[subnet.cidr_name], "NAT_GW", { self = false }).self
#   # }

#   protected_subnet_map_without_self_nat_gw = {
#     for subnet in local.all_additional_subnets :
#     "${subnet.cidr_name}-${subnet.az}-${format("%02d", subnet.index + 1)}" => subnet
#     if subnet.type == "protected" && 
#        # Perform a nested lookup to handle potentially missing 'self' attribute.
#        !lookup(lookup(var.additional_cidr[subnet.cidr_name], "NAT_GW", {}), "self", false)
#   }

#   az_in_protected_subnet_map_with_self_nat_gw = distinct([
#     for subnet in local.protected_subnet_map_with_self_nat_gw : subnet.az
#   ])

#   # az_belongs_to_dedicated_nat = flatten([
#   #   for cidr_name, cidr_data in var.additional_cidr : [
#   #     for az in cidr_data.NAT_GW.HA ? local.az_in_protected_subnet_map_with_self_nat_gw : [cidr_data.NAT_GW.Preffered_data_AZ] : {
#   #       "cidr_name" = cidr_name
#   #       "az"        = az
#   #     }
#   #   ]
#   # ])

#   # az_belongs_to_dedicated_nat = flatten([
#   #   for cidr_name, cidr_data in var.additional_cidr : [
#   #     for az in (try(cidr_data.NAT_GW.HA, false)) ? local.az_in_protected_subnet_map_with_self_nat_gw : [(try(cidr_data.NAT_GW.Preffered_data_AZ, null))] : {
#   #       "cidr_name" = cidr_name
#   #       "az"        = az
#   #     }
#   #   ]
#   # ])

#   # # worked 
#   # # az_belongs_to_dedicated_nat = flatten([
#   # #   for cidr_name, cidr_data in var.additional_cidr : [
#   # #     for az in (
#   # #       lookup(cidr_data, "NAT_GW", {}) != {} ? # Verify NAT_GW exists
#   # #         (lookup(cidr_data.NAT_GW, "HA", false) ?  # Check HA within NAT_GW
#   # #           local.az_in_protected_subnet_map_with_self_nat_gw : # Use az_in_protected_subnet_map_with_self_nat_gw if HA is true
#   # #           [lookup(cidr_data.NAT_GW, "Preffered_data_AZ", null)] # Use Preferred_data_AZ if HA is false or does not exist
#   # #         ) :
#   # #         [] # If NAT_GW does not exist, use an empty list
#   # #     ) : {
#   # #       "cidr_name" = cidr_name,
#   # #       "az"        = az
#   # #     }
#   # #     if az != null # Filter out any null AZ values
#   # #   ]
#   # # ])

#     az_belongs_to_dedicated_nat = flatten([
#     for cidr_name, cidr_data in var.additional_cidr : [
#       for az in (
#         lookup(cidr_data, "NAT_GW", {}) != {} ? # Verify NAT_GW exists
#           (lookup(cidr_data.NAT_GW, "HA", false) ?  # Check HA within NAT_GW
#             local.az_in_protected_subnet_map_with_self_nat_gw : # Use az_in_protected_subnet_map_with_self_nat_gw if HA is true
#             [lookup(cidr_data.NAT_GW, "Preffered_data_AZ", null)] # Use Preferred_data_AZ if HA is false or does not exist
#           ) :
#           [] # If NAT_GW does not exist, use an empty list
#       ) : {
#         "cidr_name" = cidr_name,
#         "az"        = az,
#         "nat_az"    = lookup(cidr_data, "NAT_GW", {}) != {} && lookup(cidr_data.NAT_GW, "HA", false) == false ? lookup(cidr_data.NAT_GW, "Preffered_data_AZ", az) : az
#       }
#       if az != null # Filter out any null AZ values
#     ]
#   ])

#   #   eip_azs = toset([
#   #     for subnet in local.all_additional_subnets :
#   #     "${subnet.cidr_name}-${local.additional_cidr[subnet.cidr_name].NAT_GW.HA ? subnet.az : local.additional_cidr[subnet.cidr_name].NAT_GW.Preffered_data_AZ}"
#   #     if subnet.type == "protected" && local.additional_cidr[subnet.cidr_name].NAT_GW.self
#   #   ])
# }

locals {
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
}


locals {

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


  # unique_az_cidr_name_combinations = distinct([
  #   for subnet in local.protected_subnet_map_with_dedicated_nat_gw : "${subnet.cidr_name}-${subnet.az}"
  # ])

  # az_belongs_to_dedicated_nat_gw = {
  #   for combination in local.unique_az_cidr_name_combinations : 
  #     combination => try(
  #       # Attempt to get the first matching subnet in the protected_subnet_map_with_dedicated_nat_gw
  #       local.protected_subnet_map_with_dedicated_nat_gw[
  #         matchkeys(
  #           keys(local.protected_subnet_map_with_dedicated_nat_gw),
  #           [for subnet in local.protected_subnet_map_with_dedicated_nat_gw : "${subnet.cidr_name}-${subnet.nat_az}"],
  #           [combination]
  #         )[0]
  #       ],
  #       null # Return null if no match found; replace with default behavior if needed
  #     )
  #     if length(matchkeys(
  #       keys(local.protected_subnet_map_with_dedicated_nat_gw),
  #       [for subnet in local.protected_subnet_map_with_dedicated_nat_gw : "${subnet.cidr_name}-${subnet.nat_az}"],
  #       [combination]
  #     )) > 0
  # }

  # # # Create a list of unique combination keys for cidr_name and nat_az.
  # # unique_combination_keys = distinct([
  # #   for subnet in local.protected_subnet_map_with_dedicated_nat_gw : 
  # #   "${subnet.cidr_name}-${subnet.nat_az}"
  # # ])

  # # # Create a map where each unique combination key points to the first subnet encountered.
  # # az_belongs_to_dedicated_nat_gw = {
  # #   for key in local.unique_combination_keys : 
  # #   key => local.protected_subnet_map_with_dedicated_nat_gw[
  # #     # Get the keys (subnet identifiers) matching our unique combination key.
  # #     [for k, s in local.protected_subnet_map_with_dedicated_nat_gw : k if "${s.cidr_name}-${s.nat_az}" == key][0]
  # #   ]
  # # }

  # filtered_subnets = [
  #   for key, subnet in local.protected_subnet_map_with_dedicated_nat_gw :
  #   subnet if subnet.az == subnet.nat_az
  # ]

  # grouped_by_unique_pairs = { for item in local.filtered_subnets :
  #   "${item.cidr_name}-${item.nat_az}" => item...
  # }

  # az_belongs_to_dedicated_nat_gw1 = [for key, value in local.grouped_by_unique_pairs : value[0]]

  az_belongs_to_dedicated_nat_gw = [
    for key, value in {
      for subnet in local.protected_subnet_map_with_dedicated_nat_gw :
      "${subnet.cidr_name}-${subnet.nat_az}" => subnet...
      if subnet.az == subnet.nat_az
    } : value[0]
  ]

  az_belongs_to_protect_additional_route_table = [
    for subnet in local.protected_subnet_map_with_dedicated_nat_gw :
      subnet if subnet.index == 0
  ]
}


# output "protected_subnet_map_with_self_nat_gw" {
#   value = local.protected_subnet_map_with_self_nat_gw
# }


# output "protected_subnet_map_without_self_nat_gw" {
#   value = local.protected_subnet_map_without_self_nat_gw
# }

output "aws_route_table_additional_protected" {
  value = aws_route_table.additional_protected
}

locals {
  environment = terraform.workspace
  vpcs_info   = lookup(var.environment, local.environment, {})

  dc = {
    "dc01" = {
      region = "ap-south-1"
      acc_id = "000000000000"
    },
    "dc02" = {
      region = "ap-south-1" # Ensure valid AWS region codes
      acc_id = "000000000000"
    }
  }
}

# locals {
#   peering_info = {
#     for k, v in local.vpcs_info : k => {
#       creator = {
#         for creator_key, creator_value in lookup(v, "peering", {}) : creator_key => {
#           dst_vpc_id = creator_value.dst_vpc_id

#           dst_acc_id = try(
#             creator_value.dst_vpc_alias != null && contains(keys(local.dc), creator_value.dst_vpc_alias) ? local.dc[creator_value.dst_vpc_alias].acc_id : creator_value.dst_acc_id,
#             creator_value.dst_acc_id
#           )
#           dst_region = try(
#             creator_value.dst_vpc_alias != null && contains(keys(local.dc), creator_value.dst_vpc_alias) ? local.dc[creator_value.dst_vpc_alias].region : creator_value.dst_region,
#             creator_value.dst_region
#           )
#         }
#       }
#     }
#   }

#   # peering_info = {
#   #   for k, v in local.vpcs_info : k => {
#   #     creator = {
#   #       for creator_key, creator_value in lookup(v, "peering", {}) : creator_key => {
#   #         dst_alias = lookup(creator_value, "dst_alias", null)
#   #         // Check if the key exists in the local.dc map and has the expected structure
#   #         dc_info = dst_alias != null && contains(keys(local.dc), dst_alias) ? local.dc[dst_alias] : {}
#   #         dst_acc_id = dst_alias != null ? lookup(dc_info, "acc_id", lookup(creator_value, "dst_acc_id", null)) : lookup(creator_value, "dst_acc_id", null)
#   #         dst_region = dst_alias != null ? lookup(dc_info, "region", lookup(creator_value, "dst_region", null)) : lookup(creator_value, "dst_region", null)
#   #         dst_vpc_id = dst_alias != null ? lookup(dc_info, "vpc_alias", lookup(creator_value, "dst_vpc_id", null)) : lookup(creator_value, "dst_vpc_id", null)
#   #       }
#   #     }
#   #   }
#   # }

#   # testing_info = lookup(lookup(local.vpcs_info.main, "peering", {}), "testing", {})

#   # peering_info = {
#   #   for k, v in local.vpcs_info: k => lookup(v, "peering", {})
#   # }

#   # creator_info = {
#   #   for k, v in local.vpcs_info: k => lookup(v.peering, "creator", {})
#   # }

#   # peering_tmp = {
#   #   #testing_info = lookup( lookup (local.vpcs_info.main, "peering", {}), "peering", {})
#   #   # for k, peer in local.vpcs_info.main.peering.  : k => {
#   #   for k, peer in local.creator_info  : k => {
#   #     # dst_vpc_id = peer.dst_vpc_id
#   #     # dst_vpc_id = (lookup(peer, "dst_vpc_alias", null) != null) ? lookup(lookup(data.terraform_remote_state.vpc, peer.dst_alias, {}).outputs.vpc_info, "main", {}).vpc_id : peer.dst_vpc_id
#   #     # dst_acc_id = (lookup(peer, "dst_alias", null) != null) ? local.dc[peer["dst_alias"]].acc_id : peer.dst_acc_id
#   #     # dst_region = (lookup(peer, "dst_alias", null) != null) ? local.dc[peer["dst_alias"]].region : peer.dst_region

#   #     dst_acc_id = peer
#   #   }
#   # }
# }


locals {
  peering_info = {
    # Loop through 'local.vpcs_info' map
    for k, v in local.vpcs_info : k => {
      # Navigate to 'peering.creator' instead of just 'peering'
      creator = {
        # for creator_key, creator_value in v.peering.creator : creator_key => {
        for creator_key, creator_value in lookup(lookup(v, "peering", {}), "creator", {}) : creator_key => {
          # dst_vpc_id = creator_value.dst_vpc_id

          dst_vpc_id   = try(creator_value.dst_vpc_id_alias != null, false) ? lookup(lookup(data.terraform_remote_state.vpc, creator_value.dst_vpc_alias, {}).outputs.vpc_info, creator_value.dst_vpc_id_alias, {}).vpc_id : creator_value.dst_vpc_id
          dst_vpc_cidr = try(creator_value.dst_vpc_id_alias != null, false) ? lookup(lookup(data.terraform_remote_state.vpc, creator_value.dst_vpc_alias, {}).outputs.vpc_info, creator_value.dst_vpc_id_alias, {}).primary_cidr : creator_value.dst_vpc_cidr

          # dst_vpc_id = try(creator_value.dst_vpc_id_alias != null, false) ? lookup(lookup(data.terraform_remote_state.vpc, creator_value.dst_vpc_alias, {}).outputs.vpc_info, k, {}).vpc_id : creator_value.dst_vpc_id  

          # creator_value.dst_vpc_id_alias != null ? lookup(lookup(data.terraform_remote_state.vpc, creator_value.dst_vpc_alias, {}).outputs.vpc_info, k, {}).vpc_id : creator_value.dst_vpc_id

          # Check if 'dst_vpc_alias' exists and is not null
          # Then check if it exists in 'local.dc' before trying to retrieve values
          dst_acc_id = try(
            creator_value.dst_vpc_alias != null && contains(keys(local.dc), creator_value.dst_vpc_alias) ? local.dc[creator_value.dst_vpc_alias].acc_id : creator_value.dst_acc_id,
            creator_value.dst_acc_id
          )
          dst_region = try(
            creator_value.dst_vpc_alias != null && contains(keys(local.dc), creator_value.dst_vpc_alias) ? local.dc[creator_value.dst_vpc_alias].region : creator_value.dst_region,
            creator_value.dst_region
          )
        }
      }
      acceptor = {
        1 = {
          peering_id = "pcx-94bd4876"
        }
      }
    }
  }
}

output "peering_info" {
  value = local.peering_info
}

# output "vpcs_info" {
#   value = local.vpcs_info
# }

# locals {
#   dc = {
#     dc01 = {
#       region = "ap-south-1"
#       acc_id = "000000000000"
#     }
#     dc02 = {
#       region = "useast" # Ensure valid AWS region codes
#       acc_id = "111111111112"
#     }
#   }
# }

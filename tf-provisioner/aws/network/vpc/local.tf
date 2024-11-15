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

locals {
  peering_info = {
    for k, v in local.vpcs_info : k => {
      creator = {
        for creator_key, creator_value in lookup(lookup(v, "peering", {}), "creator", {}) : "${creator_value.dst_vpc_alias}-${creator_value.dst_vpc_id_alias}" => {
          dst_vpc_id   = try(
            try(creator_value.dst_vpc_id_alias != null, false) ? lookup(lookup(data.terraform_remote_state.vpc, creator_value.dst_vpc_alias, {}).outputs.vpc_info, creator_value.dst_vpc_id_alias, {}).vpc_id : creator_value.dst_vpc_id, null
          )
          
          dst_vpc_cidr = try(
            try(creator_value.dst_vpc_id_alias != null, false) ? lookup(lookup(data.terraform_remote_state.vpc, creator_value.dst_vpc_alias, {}).outputs.vpc_info, creator_value.dst_vpc_id_alias, {}).all_cidrs : creator_value.dst_vpc_cidr, []
          )

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
        for acceptor_key, acceptor_value in lookup(lookup(v, "peering", {}), "acceptor", {}) : "${acceptor_value.src_vpc_region_alias}-${acceptor_value.src_vpc_logical_name}" => {
          peering_dst_cidr = try(try(acceptor_value.src_vpc_logical_name != null, false) ? lookup(lookup(data.terraform_remote_state.vpc, acceptor_value.src_vpc_region_alias, {}).outputs.vpc_info, acceptor_value.src_vpc_logical_name, {}).all_cidrs : acceptor_value.src_vpc_cidr, [])

          # peering_id = try([for peering in lookup(lookup(data.terraform_remote_state.vpc, acceptor_value.src_vpc_region_alias, null).outputs.peering_ids.creator, acceptor_value.src_vpc_logical_name, null): peering.peering_id if peering.dst_vpc_id == (lookup(lookup(data.terraform_remote_state.vpc, local.environment, {}).outputs.vpc_info, k, {}).vpc_id)][0], null)
          # peering_id = try([for peering in lookup(lookup(data.terraform_remote_state.vpc, acceptor_value.src_vpc_region_alias, null).outputs.peering_ids.creator, acceptor_value.src_vpc_logical_name, null): peering.peering_id if peering.dst_vpc_id == (lookup(lookup(data.terraform_remote_state.vpc, local.environment, {}).outputs.vpc_info, k, {}).vpc_id)][0], null)
          peering_id = try({ for pc in lookup(lookup(data.terraform_remote_state.vpc, acceptor_value.src_vpc_region_alias, null).outputs.peering_ids.creator, acceptor_value.src_vpc_logical_name, null): pc.dst_vpc_id => pc.peering_id }[lookup(lookup(data.terraform_remote_state.vpc, local.environment, {}).outputs.vpc_info, k, {}).vpc_id], null)

        }
      }
    }
  }
}

output "peering_info" {
  value = local.peering_info
}
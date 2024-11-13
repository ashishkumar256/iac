# output "vpc_info" {
#   value       = { for info, vpc in module.vpc : info => vpc.vpc_id }
#   description = "A map of VPC keys to their corresponding VPC IDs."
# }

output "vpc_info" {
  description = "The ID and CIDR blocks of VPC with additional CIDRs from the VPC module"
  # value       = module.vpc.main.vpc_info

  value = {
        for vpc, info in module.vpc : vpc => info.vpc_info
    }
}

output "peering_ids" {
  value = { 
    "creator" = {
        for vpc, info in module.vpc : vpc => info.vpc_peering_id
    }
  }
}


# output "tmp" {
#   value = {
#         for vpc, info in module.vpc : vpc => info.tmp
#     }
#   # value = local.peering_info
# }
# output "vpc_info" {
#   description = "The ID and CIDR blocks of VPC with additional CIDRs from the VPC module"
#   # value       = module.vpc.main.vpc_info

#   value = {
#         for vpc, info in module.vpc : vpc => info.vpc_info
#     }
# }

# output "peering_ids" {
#   value = { 
#     "creator" = {
#         for vpc, info in module.vpc : vpc => info.vpc_peering_id
#     }
#   }
# }

# output "vpc_info" {
#   value       = { for info, vpc in module.vpc : info => vpc.vpc_id }
#   description = "A map of VPC keys to their corresponding VPC IDs."
# }

# output "tmp" {
#   value = {
#         for vpc, info in module.vpc : vpc => info.tmp
#     }
#   # value = local.peering_info
# }

# output "az_belongs_to_dedicated_nat" {
#   value =  module.vpc.main.az_belongs_to_dedicated_nat
# }

# output "protected_subnet_map_with_self_nat_gw" {
#   value = module.vpc.main.protected_subnet_map_with_self_nat_gw
# }

# output "protected_subnet_map_without_self_nat_gw" {
#   value = module.vpc.main.protected_subnet_map_without_self_nat_gw
# }

# output "aws_route_table_additional_protected" {
#   value = module.vpc.main.aws_route_table_additional_protected
# }

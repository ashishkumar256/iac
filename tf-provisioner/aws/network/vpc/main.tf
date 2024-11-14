module "vpc" {
  #source             = "git@github.com:moengage/terraform-modules.git//aws/network/vpc"
  source = "/Users/ashish.singh/iac/tf-modules/aws/network/vpc"

  for_each        = local.vpcs_info
  name            = each.key
  environment     = local.environment
  region          = each.value.region
  cidr            = each.value.cidr
  subnets         = each.value.subnets
  nat_gw          = each.value.nat_gw
  additional_cidr = try(each.value.additional_cidr, {})
  endpoint        = try(each.value.endpoint, {})
  peering         = lookup(local.peering_info, each.key, {}) #{} #try(each.value.peering, {})

  # providers = {
  #   aws = aws.dc01
  # }

  # providers = {
  #   aws         = aws.default
  #   aws.alternate = aws.alternate
  # }  

  # gateway_endpoint = each.value.gateway_endpoint
  # interface_endpoint = each.value.interface_endpoint
  #   public_subnets     = each.value.public_subnets
  #   availability_zones = each.value.availability_zones
  #   private_endpoints  = each.value.private_endpoints
  #   peering_creator    = lookup(local.peering_creator, each.key, {})
  #   peering_acceptor   = lookup(local.peering_acceptor, each.key, {})
  #   # flow_logs          = each.value.flow_logs
  #   # extra_tags         = each.value.extra_tags
  #   providers = { aws = aws.sre }
}

module "vpc" {
  #source             = "git@github.com:moengage/terraform-modules.git//aws/network/vpc"
  source = "/Users/ashish.singh/iac-1/tf-modules/aws/network/vpc"

  for_each        = local.vpcs_info
  name            = each.key
  environment     = local.environment
  region          = each.value.region
  cidr            = each.value.cidr
  subnets         = each.value.subnets
  nat_gw          = each.value.nat_gw
  additional_cidr = try(each.value.additional_cidr, {})
  endpoint        = try(each.value.endpoint, {})
  peering         = {} #lookup(local.peering_info, each.key, {}) #{} #try(each.value.peering, {})
}

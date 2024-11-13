# data "terraform_remote_state" "vpc" {
#   #   for_each = var.environment
#   workspace = "dc00"

#   backend = "s3"
#   config = {
#     bucket = "centralized-tfstate"
#     key    = "network/aws/vpc.tfstate"
#     region = "ap-south-1"

#     endpoints = { s3 = "http://localhost:4566" }

#     # LocalStack S3 doesn't support versioning yet
#     # so we need to disable it
#     skip_region_validation      = true
#     skip_credentials_validation = true
#     # skip_get_ec2_platforms      = true
#     skip_metadata_api_check = true
#     use_path_style          = true
#   }
# }

# output "vpc" {
#   value = data.terraform_remote_state.vpc
# }

data "aws_caller_identity" "current" {}


data "terraform_remote_state" "vpc" {
  for_each = var.environment
  workspace = "${each.key}"

  backend = "s3"

  config = {
    bucket = "centralized-tfstate"
    key    = "network/aws/vpc.tfstate"
    region = "ap-south-1"

    # If using LocalStack or a similar local S3 service
    endpoints = {
      s3 = "http://localhost:4566"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}

output "peering_details" {
  value = { 
    for key, instance in data.terraform_remote_state.vpc : key => instance.outputs.peering_ids.creator
  }
}

# output "terraform_remote_state" {
#   # value = lookup(lookup(data.terraform_remote_state.vpc, "dc02", {}).outputs.vpc_info, "main", {}).primary_cidr
#   # value = data.terraform_remote_state.vpc
#   value = lookup(lookup(data.terraform_remote_state.vpc, "dc02", {}).outputs.vpc_info, "main", {}).vpc_id
# }
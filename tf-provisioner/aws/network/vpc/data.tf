data "aws_caller_identity" "current" {}


# data "terraform_remote_state" "vpc" {
#   for_each = var.environment
#   workspace = "${each.key}"

#   backend = "s3"

#   config = {
#     bucket = "centralized-tfstate"
#     key    = "network/aws/vpc.tfstate"
#     region = "ap-south-1"

#     # If using LocalStack or a similar local S3 service
#     endpoints = {
#       s3 = "http://localhost:4566"
#     }

#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     use_path_style              = true
#   }
# }

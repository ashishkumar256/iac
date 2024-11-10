terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#central account
provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "ap-south-1"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2            = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    # sts            = "http://localhost:4566"
    sts = "http://localstack.local:4566"
    # s3             = "http://s3.localhost.localstack.cloud:4566"

  }
}

# #dc01 account
# provider "aws" {
#   alias      = "dc01"
#   access_key = "test"
#   secret_key = "test"
#   region     = "ap-south-1"

#   skip_credentials_validation = true
#   skip_metadata_api_check     = true
#   skip_requesting_account_id  = true
#   endpoints {
#     ec2            = "http://localhost:4666"
#     apigateway     = "http://localhost:4666"
#     cloudformation = "http://localhost:4666"
#     cloudwatch     = "http://localhost:4666"
#     dynamodb       = "http://localhost:4666"
#     es             = "http://localhost:4666"
#     firehose       = "http://localhost:4666"
#     iam            = "http://localhost:4666"
#     kinesis        = "http://localhost:4666"
#     lambda         = "http://localhost:4666"
#     route53        = "http://localhost:4666"
#     redshift       = "http://localhost:4666"
#     s3             = "http://localhost:4666"
#     secretsmanager = "http://localhost:4666"
#     ses            = "http://localhost:4666"
#     sns            = "http://localhost:4666"
#     sqs            = "http://localhost:4666"
#     ssm            = "http://localhost:4666"
#     stepfunctions  = "http://localhost:4666"
#     sts            = "http://localhost:4666"
#   }
# }


# #dc02 account
# provider "aws" {
#   alias      = "dc02"
#   access_key = "test"
#   secret_key = "test"
#   region     = "ap-south-1"

#   skip_credentials_validation = true
#   skip_metadata_api_check     = true
#   skip_requesting_account_id  = true
#   endpoints {
#     apigateway     = "http://localhost:4766"
#     cloudformation = "http://localhost:4766"
#     cloudwatch     = "http://localhost:4766"
#     dynamodb       = "http://localhost:4766"
#     es             = "http://localhost:4766"
#     firehose       = "http://localhost:4766"
#     iam            = "http://localhost:4766"
#     kinesis        = "http://localhost:4766"
#     lambda         = "http://localhost:4766"
#     route53        = "http://localhost:4766"
#     redshift       = "http://localhost:4766"
#     s3             = "http://localhost:4766"
#     secretsmanager = "http://localhost:4766"
#     ses            = "http://localhost:4766"
#     sns            = "http://localhost:4766"
#     sqs            = "http://localhost:4766"
#     ssm            = "http://localhost:4766"
#     stepfunctions  = "http://localhost:4766"
#     sts            = "http://localhost:4766"
#     ec2            = "http://localhost:4766"
#   }
# }

terraform {
  backend "s3" {
    bucket = "centralized-tfstate"
    key    = "network/aws/vpc.tfstate"
    region = "ap-south-1"
    endpoints = {
      s3 = "http://localhost:4566"
    }

    # LocalStack S3 doesn't support versioning yet
    # so we need to disable it
    skip_region_validation      = true
    skip_credentials_validation = true
    # skip_get_ec2_platforms      = true
    skip_metadata_api_check = true
    use_path_style          = true
  }
}

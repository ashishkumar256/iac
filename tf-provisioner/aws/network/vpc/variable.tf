variable "environment" {
  description = "the name of your environment, e.g. \"dev, stg, uat, prd\""
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "ap-south-1"
}
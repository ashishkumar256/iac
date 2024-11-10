variable "name" {
  description = "Name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "Name of your environment, e.g. \"prod\""
}

variable "region" {
  description = "AWS region, e.g. \"ap-south-1\""
  default = "ap-south-1"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
}

variable "subnets" {
}

variable "nat_gw" {
}

variable "additional_cidr" {
}

# variable "gateway_endpoint" {
  
# }

# variable "interface_endpoint" {
  
# }

variable "endpoint" {
  
}

variable "peering" {
  
}
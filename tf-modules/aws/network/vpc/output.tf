# output "vpc_id" {
#   description = "The ID of the VPC"
#   value = { 
#     vpc_id = aws_vpc.main.id,
#     cidrs = aws_vpc.main.cidr_block
#     additional_cidrs = aws_vpc.main.secondary_cidr_blocks
#   }
#   # value = aws_vpc.main
# }

output "vpc_info" {
  description = "The ID and CIDR blocks of VPC with additional CIDRs"
  value       = {
    vpc_id        = aws_vpc.main.id
    primary_cidr  = aws_vpc.main.cidr_block
    additional_cidrs = [for cidr_assoc in aws_vpc_ipv4_cidr_block_association.additional_cidr : cidr_assoc.cidr_block]
    all_cidrs = concat([aws_vpc.main.cidr_block], [for cidr_assoc in aws_vpc_ipv4_cidr_block_association.additional_cidr : cidr_assoc.cidr_block])
  }
}

output "vpc_peering_id" {
  # value = {
  #   for peering, info in aws_vpc_peering_connection.main :
  #   "${aws_vpc.main.id}:${info.peer_vpc_id}" => info.id
  # }

  value = [
    for peering, info in aws_vpc_peering_connection.main :  {
      src_vpc_id        = aws_vpc.main.id
      dst_vpc_id        = info.peer_vpc_id
      peering_id        = info.id
    }
  ]
}


# output "tmp" {
#   value = var.peering.dst_vpc_cidr
# }

# output "tmp" {
#   value = values(aws_vpc_peering_connection.main)[*].id
# }

# output "vpc_peering_accept_status" {
#   # value = {
#   #   for peering, info in aws_vpc_peering_connection.main :
#   #   "${aws_vpc.main.id}:${info.peer_vpc_id}" => info.accept_status
#   # }

#   value = {
#     for peering, info in aws_vpc_peering_connection_accepter.main :
#     "${aws_vpc.main.id}:${info.peer_vpc_id}" => info.accept_status
#   }  
# }

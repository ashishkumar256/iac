resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-${var.name}-vpc"
    Environment = var.environment
  }
}


resource "aws_vpc_ipv4_cidr_block_association" "additional_cidr" {
  for_each = var.additional_cidr

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr
}


resource "aws_subnet" "public" {
  for_each = local.flattened_public_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = local.flattened_private_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_subnet" "protected" {
  for_each = local.flattened_protected_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${var.name}-protected-${each.key}"
  }
}


resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-ig"
  }
}

resource "aws_eip" "nat" {
  for_each = var.nat_gw.HA ? toset([for az, details in var.subnets : az if can(details.protected)]) : toset([var.nat_gw.Preffered_data_AZ])
  domain   = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${each.key}"
  }

  lifecycle {
    prevent_destroy = false
  }

}


resource "aws_nat_gateway" "nat" {
  for_each      = var.nat_gw.HA ? toset([for az, details in var.subnets : az if can(details.protected)]) : toset([var.nat_gw.Preffered_data_AZ])
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[format("%s-01", each.key)].id

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route_table" "protected" {
  for_each = var.nat_gw.HA ? toset([for az, details in var.subnets : az if can(details.protected)]) : toset([var.nat_gw.Preffered_data_AZ])

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-protected-rt-${each.key}"
  }
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}


resource "aws_route" "protected_nat" {
  for_each               = aws_nat_gateway.nat
  nat_gateway_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.protected[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = local.flattened_public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "protected" {
  for_each = local.flattened_protected_subnets

  subnet_id      = aws_subnet.protected[each.key].id
  route_table_id = var.nat_gw.HA ? aws_route_table.protected[each.value.az].id : aws_route_table.protected["${var.nat_gw.Preffered_data_AZ}"].id
}

resource "aws_route_table_association" "private" {
  for_each = local.flattened_private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}


# Subnet resource block for additional public subnets
resource "aws_subnet" "additional_public" {
  for_each = local.public_subnet_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-pub-${each.key}"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.additional_cidr]
}

# Subnet resource block for additional private subnets
resource "aws_subnet" "additional_private" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${var.name}-pvt-${each.key}"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.additional_cidr]
}

# Subnet resource block for additional protected subnets
resource "aws_subnet" "additional_protected" {
  for_each = local.protected_subnet_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${var.name}-ptd-${each.key}"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.additional_cidr]

}

resource "aws_route_table_association" "additional_public" {
  for_each = local.public_subnet_map

  subnet_id      = aws_subnet.additional_public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "additional_private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.additional_private[each.key].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "additional_protected" {
  for_each = local.protected_subnet_map_without_self_nat_gw

  subnet_id      = aws_subnet.additional_protected[each.key].id
  route_table_id = var.nat_gw.HA ? aws_route_table.additional_nat_protected[each.value.az].id : aws_route_table.protected["${var.nat_gw.Preffered_data_AZ}"].id

}


resource "aws_eip" "additional_nat" {
  for_each = { for eip in local.az_belongs_to_dedicated_nat : "${eip.cidr_name}-${eip.az}" => eip }


  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "additional_nat" {
  for_each = { for eip in local.az_belongs_to_dedicated_nat : "${eip.cidr_name}-${eip.az}" => eip }

  allocation_id = aws_eip.additional_nat[each.key].id
  subnet_id     = aws_subnet.public[format("%s-01", regex("[^-]*-(.*)", each.key)[0])].id

  tags = {
    Name = "${var.name}-additional-nat-${each.key}"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.additional_cidr]
}


resource "aws_route_table" "additional_nat_protected" {
  for_each = { for eip in local.az_belongs_to_dedicated_nat : "${eip.cidr_name}-${eip.az}" => eip }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-additional-protected-rt-${each.key}"
  }
}

# # Create Routes for NAT Gateways in protected subnets
resource "aws_route" "additional_nat_protected" {
  for_each = { for eip in local.az_belongs_to_dedicated_nat : "${eip.cidr_name}-${eip.az}" => eip }

  route_table_id         = aws_route_table.additional_nat_protected[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.additional_nat[each.key].id
}

resource "aws_route_table_association" "additional_nat_protected" {
  for_each = local.protected_subnet_map_without_self_nat_gw

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.additional_nat_protected[each.key].id
}

# Gateway endpoint
resource "aws_vpc_endpoint" "gateway" {
  for_each      = toset(lookup(var.endpoint, "gateway", []))

  vpc_id       = aws_vpc.main.id
  service_name = join(".", ["com.amazonaws", var.region, each.key])
}


resource "aws_vpc_endpoint_route_table_association" "aws_vpc_endpoint_gateway" {
  for_each = tomap({
    for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_nat_protected), ["public", "private"]), keys(aws_vpc_endpoint.gateway)) : "${pair[0]}-${pair[1]}" => {
      route_table_id = (
        pair[0] == "public" ? aws_route_table.public.id :
        pair[0] == "private" ? aws_route_table.private.id :
        (
          lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
          lookup(aws_route_table.additional_nat_protected, pair[0], null) != null ? aws_route_table.additional_nat_protected[pair[0]].id :
          null
        )
      ),
      vpc_endpoint_id = aws_vpc_endpoint.gateway[pair[1]].id
    }
  })

  route_table_id  = each.value.route_table_id
  vpc_endpoint_id = each.value.vpc_endpoint_id
}


resource "aws_security_group" "interface_vpce" {
  name        = "${var.environment}-vpc-endpoints-sg"
  description = "SG for vpc endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each      = toset(lookup(var.endpoint, "interface", []))

  private_dns_enabled = true
  vpc_id              = aws_vpc.main.id
  service_name        = join(".", ["com.amazonaws", var.region, replace(each.key, "-", ".")])
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.interface_vpce.id]
  subnet_ids          = concat(values(aws_subnet.protected)[*].id, values(aws_subnet.additional_protected)[*].id)

  tags = { Name = "${var.environment}-${var.name}-${each.key}-interface" }
}

resource "aws_vpc_peering_connection" "main" {
  for_each      = lookup(var.peering, "creator", {})
  vpc_id        = aws_vpc.main.id
  peer_owner_id = each.value.dst_acc_id
  peer_vpc_id   = each.value.dst_vpc_id
  peer_region   = each.value.dst_region

  tags = {
    Name = "peering-connection-${each.key}"
  }

  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_route" "creater_peering" {
  for_each = { for idx, obj in flatten([
    for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_nat_protected), ["public", "private"]), keys(var.peering["creator"])) :
    [
      for dst_cidr in var.peering["creator"][pair[1]].dst_vpc_cidr :
      {
        "key" = "${pair[0]}-${pair[1]}-${replace(dst_cidr, "/", "-")}",
        "value" = {
          "route_table_id" = (
            pair[0] == "public" ? aws_route_table.public.id :
            pair[0] == "private" ? aws_route_table.private.id :
            (
              lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
              lookup(aws_route_table.additional_nat_protected, pair[0], null) != null ? aws_route_table.additional_nat_protected[pair[0]].id :
              null
            )
          ),
          "peering_connection_id" = aws_vpc_peering_connection.main[pair[1]].id,
          "destination_cidr_block" = dst_cidr
        }
      }
      if var.peering["creator"][pair[1]].dst_acc_id != null // only create routes if the destination account ID is set
    ]
  ]) : obj.key => obj.value }

  route_table_id             = each.value.route_table_id
  destination_cidr_block     = each.value.destination_cidr_block
  vpc_peering_connection_id  = each.value.peering_connection_id

  # tags = {
  #   Name = "peering-route-${each.key}"
  # }

  # Ensure the route is created only after the VPC peering connection is active
  depends_on = [
    aws_vpc_peering_connection.main
  ]
}

## below working 
# resource "aws_route" "creater_peering" {
#   for_each = tomap({
#     for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_nat_protected), ["public", "private"]), keys(var.peering["creator"])) :
#     "${pair[0]}-${pair[1]}" => {
#       route_table_id = (
#         pair[0] == "public" ? aws_route_table.public.id :
#         pair[0] == "private" ? aws_route_table.private.id :
#         (
#           lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
#           lookup(aws_route_table.additional_nat_protected, pair[0], null) != null ? aws_route_table.additional_nat_protected[pair[0]].id :
#           null
#         )
#       ),
#       peering_connection_id = aws_vpc_peering_connection.main[pair[1]].id
#     }
#     if var.peering["creator"][pair[1]].dst_acc_id != null // only create routes if the destination account ID is set
#   })

#   route_table_id             = each.value.route_table_id
#   destination_cidr_block     = "10.1.0.0/16" // Modify accordingly to your CIDR block for the peered VPC
#   vpc_peering_connection_id  = each.value.peering_connection_id

#   # # Example tags
#   # tags = {
#   #   Name = "peering-route-${each.key}"
#   # }
  
#   # Ensure the route is created only after the VPC peering connection is active
#   depends_on = [
#     aws_vpc_peering_connection.main
#   ]
# }

# resource "aws_route" "creater_peering" {
#   for_each = tomap({
#     for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_nat_protected), ["public", "private"]), keys(aws_vpc_peering_connection.main)) : 
#     "${pair[0]}-${pair[1]}" => {
#       route_table_id = (
#         pair[0] == "public" ? aws_route_table.public.id :
#         pair[0] == "private" ? aws_route_table.private.id :
#         (
#           lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
#           lookup(aws_route_table.additional_nat_protected, pair[0], null) != null ? aws_route_table.additional_nat_protected[pair[0]].id :
#           null
#         )
#       ),
#       peering_connection_id = aws_vpc_peering_connection.main[pair[1]].id
#     }
#     if aws_vpc_peering_connection.main[pair[1]].accept_status == "active"
#   })

#   route_table_id         = each.value.route_table_id
#   destination_cidr_block = "10.0.0.0/16" # Modify accordingly to your CIDR block for the peered VPC
#   vpc_peering_connection_id = each.value.peering_connection_id

#   # # Example tags
#   # tags = {
#   #   Name = "peering-route-${each.key}"
#   # }
# }

# resource "aws_route" "creater_peering" {
#   for_each = tomap({
#     for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_nat_protected), ["public", "private"]), keys(aws_vpc_peering_connection.main)) : 
#     "${pair[0]}-${pair[1]}" => {
#       route_table_id = (
#         pair[0] == "public" ? aws_route_table.public.id :
#         pair[0] == "private" ? aws_route_table.private.id :
#         (
#           lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
#           lookup(aws_route_table.additional_nat_protected, pair[0], null) != null ? aws_route_table.additional_nat_protected[pair[0]].id :
#           null
#         )
#       ),
#       peering_connection_id = aws_vpc_peering_connection.main[pair[1]].id
#     }
#     if aws_vpc_peering_connection.main[pair[1]].accept_status == "active"
#   })

#   route_table_id         = each.value.route_table_id
#   destination_cidr_block = "10.0.0.0/16" # Modify accordingly to your CIDR block for the peered VPC
#   vpc_peering_connection_id = each.value.peering_connection_id

#   # Example tags
#   # tags = {
#   #   Name = "peering-route-${each.key}"
#   # }
# }

# Ensure you adjust route_table_id and destination_cidr_block values based on your specific situation

# Ensure you adjust route_table_id and destination_cidr_block values based on your specific situation


resource "aws_vpc_peering_connection_accepter" "main" {
  for_each      = lookup(var.peering, "acceptor", {})

  vpc_peering_connection_id = each.value.peering_id
  auto_accept               = true
  tags = {
    Name = "peering-connection-${each.key}"
  }

  depends_on = [
    aws_vpc.main
  ]
}

# resource "aws_route" "acceptor_peering" {
#   for_each = tomap({
#     for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_nat_protected), ["public", "private"]), keys(aws_vpc_peering_connection_accepter.main)) : 
#     "${pair[0]}-${pair[1]}" => {
#       route_table_id = (
#         pair[0] == "public" ? aws_route_table.public.id :
#         pair[0] == "private" ? aws_route_table.private.id :
#         (
#           lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
#           lookup(aws_route_table.additional_nat_protected, pair[0], null) != null ? aws_route_table.additional_nat_protected[pair[0]].id :
#           null
#         )
#       ),
#       peering_connection_id = aws_vpc_peering_connection_accepter.main[pair[1]].id
#     }
#     if aws_vpc_peering_connection_accepter.main[pair[1]].accept_status == "active"
#   })

#   route_table_id         = each.value.route_table_id
#   destination_cidr_block = "10.0.0.0/16" # Modify accordingly to your CIDR block for the peered VPC
#   vpc_peering_connection_id = each.value.peering_connection_id

#   # # Example tags
#   # tags = {
#   #   Name = "peering-route-${each.key}"
#   # }
# }

# resource "random_pet" "aws_vpc_endpoint_gateway" {
#   for_each = merge(
#     # Create pairs for aws_route_table.public and aws_vpc_endpoint.gateway
#     { for idx in setproduct(keys(aws_route_table.protected), keys(aws_vpc_endpoint.gateway)) :
#       "${idx[0]}-${idx[1]}" => {
#         route_table_id = aws_route_table.protected[idx[0]].id,
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[idx[1]].id
#       }
#     },
#     { for idx in setproduct(keys(aws_route_table.additional_nat_protected), keys(aws_vpc_endpoint.gateway)) :
#       "${idx[0]}-${idx[1]}" => {
#         route_table_id = aws_route_table.additional_nat_protected[idx[0]].id,
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[idx[1]].id
#       }
#     },
#     { for vpce_key in keys(aws_vpc_endpoint.gateway) : 
#       "private-${vpce_key}" => {
#         route_table_id = aws_route_table.public.id, // Referencing the single public route table
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[vpce_key].id,
#         type = "Public"
#       }
#     },
#     { for vpce_key in keys(aws_vpc_endpoint.gateway) : 
#       "public-${vpce_key}" => {
#         route_table_id = aws_route_table.private.id, // Referencing the single public route table
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[vpce_key].id,
#         type = "Private"
#       }
#     }            
#   )

#   # You'll need to define what prefix or other attributes you want to set for the random_pet resource.
#   prefix = "${each.value.route_table_id}-${each.value.vpc_endpoint_id}"
# }


# resource "aws_vpc_endpoint_route_table_association" "aws_vpc_endpoint_gateway" {
#   for_each = merge(
#     # Create pairs for aws_route_table.protected and aws_vpc_endpoint.gateway
#     { for idx in setproduct(keys(aws_route_table.protected), keys(aws_vpc_endpoint.gateway)) :
#       "${idx[0]}-${idx[1]}" => {
#         route_table_id = aws_route_table.protected[idx[0]].id,
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[idx[1]].id
#       }
#     },
#     # Create pairs for aws_route_table.additional_nat_protected and aws_vpc_endpoint.gateway
#     { for idx in setproduct(keys(aws_route_table.additional_nat_protected), keys(aws_vpc_endpoint.gateway)) :
#       "${idx[0]}-${idx[1]}" => {
#         route_table_id = aws_route_table.additional_nat_protected[idx[0]].id,
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[idx[1]].id
#       }
#     },
#     # Create pairs for aws_route_table.public and aws_vpc_endpoint.gateway
#     { for vpce_key in keys(aws_vpc_endpoint.gateway) :
#       "public-${vpce_key}" => {
#         route_table_id = aws_route_table.public.id,
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[vpce_key].id
#       }
#     },
#     # Create pairs for aws_route_table.private and aws_vpc_endpoint.gateway
#     { for vpce_key in keys(aws_vpc_endpoint.gateway) :
#       "private-${vpce_key}" => {
#         route_table_id = aws_route_table.private.id,
#         vpc_endpoint_id = aws_vpc_endpoint.gateway[vpce_key].id
#       }
#     }  
#   )

#   route_table_id  = each.value.route_table_id
#   vpc_endpoint_id = each.value.vpc_endpoint_id
# }

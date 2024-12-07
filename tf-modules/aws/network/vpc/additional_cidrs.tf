resource "aws_vpc_ipv4_cidr_block_association" "additional_cidr" {
  for_each = var.additional_cidr

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr
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

# ###############
resource "aws_eip" "additional_protected" {
  for_each = { for nat in local.az_belongs_to_dedicated_nat_gw : "${nat.cidr_name}-${nat.az}" => nat }


  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "additional_protected" {
  for_each = { for nat in local.az_belongs_to_dedicated_nat_gw : "${nat.cidr_name}-${nat.az}" => nat }

  allocation_id = aws_eip.additional_protected[each.key].id
  subnet_id     = aws_subnet.public[format("%s-01", regex("[^-]*-(.*)", each.key)[0])].id

  tags = {
    Name = "${var.name}-additional-nat-${each.key}"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.additional_cidr]
}


resource "aws_route_table_association" "additional_protected_without_dedicated_nat" {
  for_each = local.protected_subnet_map_without_dedicated_nat_gw

  subnet_id      = aws_subnet.additional_protected[each.key].id
  route_table_id = var.nat_gw.HA ? aws_route_table.protected[each.value.az].id : aws_route_table.protected["${var.nat_gw.Preffered_data_AZ}"].id
}

resource "aws_route_table_association" "additional_protected_with_dedicated_nat" {
  for_each = local.protected_subnet_map_with_dedicated_nat_gw

  subnet_id      = aws_subnet.additional_protected[each.key].id
  route_table_id = aws_route_table.additional_protected["${each.value.cidr_name}-${each.value.nat_az}"].id 
}

resource "aws_route_table" "additional_protected" {
  for_each = { for nat in local.az_belongs_to_protected_additional_route_table : "${nat.cidr_name}-${nat.az}" => nat }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-additional-protected-rt-${each.key}"
  }
}

resource "aws_route" "additional_protected" {
  for_each = { for nat in local.az_belongs_to_protected_additional_route_table : "${nat.cidr_name}-${nat.az}" => nat }

  route_table_id         = aws_route_table.additional_protected["${each.value.cidr_name}-${each.value.az}"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.additional_protected["${each.value.cidr_name}-${each.value.nat_az}"].id
}
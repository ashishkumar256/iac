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


resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-ig"
  }
}

resource "aws_eip" "protected" {
  for_each = var.nat_gw.HA ? toset([for az, details in var.subnets : az if can(details.protected)]) : toset([var.nat_gw.Preffered_data_AZ])
  domain   = "vpc"

  tags = {
    Name = "${var.name}-nat-eip-${each.key}"
  }

  lifecycle {
    prevent_destroy = false
  }

}


resource "aws_nat_gateway" "protected" {
  for_each      = var.nat_gw.HA ? toset([for az, details in var.subnets : az if can(details.protected)]) : toset([var.nat_gw.Preffered_data_AZ])
  allocation_id = aws_eip.protected[each.key].id
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

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public.id
}


resource "aws_route" "protected" {
  for_each               = aws_nat_gateway.protected
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


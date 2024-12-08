# Gateway endpoint
resource "aws_vpc_endpoint" "gateway" {
  for_each      = toset(lookup(var.endpoint, "gateway", []))

  vpc_id       = aws_vpc.main.id
  service_name = join(".", ["com.amazonaws", var.region, each.key])
}


resource "aws_vpc_endpoint_route_table_association" "aws_vpc_endpoint_gateway" {
  for_each = tomap({
    for pair in setproduct(concat(keys(aws_route_table.protected), keys(aws_route_table.additional_protected), ["public", "private"]), keys(aws_vpc_endpoint.gateway)) : "${pair[0]}-${pair[1]}" => {
      route_table_id = (
        pair[0] == "public" ? aws_route_table.public.id :
        pair[0] == "private" ? aws_route_table.private.id :
        (
          lookup(aws_route_table.protected, pair[0], null) != null ? aws_route_table.protected[pair[0]].id :
          lookup(aws_route_table.additional_protected, pair[0], null) != null ? aws_route_table.additional_protected[pair[0]].id :
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

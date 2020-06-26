data "aws_availability_zones" "current" {}

resource "aws_vpc" "development" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_security_group" "development" {
  name        = var.name
  description = "Rules to allow SSH access"
  vpc_id      = aws_vpc.development.id
}

resource "aws_security_group_rule" "allow_ingress_ssh" {
  type              = "ingress"
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  security_group_id = aws_security_group.development.id
}

resource "aws_security_group_rule" "allow_egress_all" {
  type              = "egress"
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_security_group.development.id
}

resource "aws_subnet" "development" {
  count                   = length(data.aws_availability_zones.current.zone_ids)
  cidr_block              = cidrsubnet(var.vpc_cidr_block, var.subnets.public.newbits, var.subnets.public.netnum + count.index)
  vpc_id                  = aws_vpc.development.id
  availability_zone_id    = data.aws_availability_zones.current.zone_ids[count.index]
  map_public_ip_on_launch = true
}

resource "aws_egress_only_internet_gateway" "development" {
  vpc_id = aws_vpc.development.id
}

resource "aws_route" "r" {
  route_table_id         = aws_vpc.development.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  egress_only_gateway_id = aws_egress_only_internet_gateway.development.id
}


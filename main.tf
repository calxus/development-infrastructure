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

resource "aws_security_group_rule" "allow_ingress_vnc" {
  type              = "ingress"
  to_port           = 5901
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 5901
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

resource "aws_internet_gateway" "development" {
  vpc_id = aws_vpc.development.id
}

resource "aws_route" "egress_traffic" {
  route_table_id         = aws_vpc.development.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.development.id
}

resource "tls_private_key" "tactical" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tactical" {
  key_name   = "tactical"
  public_key = tls_private_key.tactical.public_key_openssh
}

resource "aws_s3_bucket_object" "tactical_key" {
  key     = "config/tactical.pem"
  bucket  = var.bucket
  content = tls_private_key.tactical.private_key_pem
}

data "template_file" "tactical" {
  template = file("tactical_user_data.sh")
  vars = {
    tactical_user     = var.tactical_user
    tactical_password = var.tactical_password
  }
}

resource "aws_instance" "tactical" {
  ami                         = var.tactical_ami_id
  instance_type               = "t2.large"
  vpc_security_group_ids      = [aws_security_group.development.id]
  subnet_id                   = aws_subnet.development[0].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.tactical.key_name
  user_data                   = data.template_file.tactical.rendered
  root_block_device {
    volume_type = "standard"
    volume_size = "60"
  }
  tags = {
    Name = "tactical"
  }
}

resource "aws_volume_attachment" "tactical" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.tactical.id
  instance_id  = aws_instance.tactical.id
  skip_destroy = true
}

resource "aws_ebs_volume" "tactical" {
  availability_zone = data.aws_availability_zones.current.names[0]
  size              = 100
}
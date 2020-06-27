variable "name" {
  type    = string
  default = "development-infrastructure"
}

variable "vpc_cidr_block" {
  type = string
}

variable "region" {
  type = string
}

variable "tactical_ami_id" {
  type = string
}

variable "bucket" {
  type = string
}

variable "tactical_password" {
  type = string
}

variable "tactical_user" {
  type = string
}

variable "subnets" {
  description = "define sizes for subnets using Terraform cidrsubnet function. For an empty /24 VPC, the defaults will create /28 public subnets and /26 private subnets, one of each in each AZ."
  type        = map(map(number))
  default = {
    public = {
      newbits = 4
      netnum  = 0
    }
    private = {
      newbits = 2
      netnum  = 1
    }
  }
}
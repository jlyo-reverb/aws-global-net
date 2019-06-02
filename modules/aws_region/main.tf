provider "aws" {
  version = "~> 2.0"
  region  = "${var.region}"
}

data "aws_availability_zones" "azs" {}

resource "aws_vpc" "vpc" {
  cidr_block                       = "${var.cidr_block}"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${var.region}.${var.domain}"
  }
}

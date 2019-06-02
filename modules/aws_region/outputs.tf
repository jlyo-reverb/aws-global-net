output "vpc_id" {
  description = "VPC ID"
  value = "${aws_vpc.vpc.id}"
}

output "vpc_arn" {
  description = "VPC ANR"
  value = "${aws_vpc.vpc.arn}"
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value = "${aws_vpc.vpc.cidr_block}"
}

output "vpc_ipv6_cidr_block" {
  description = "VPC IPv6 CIDR block"
  value = "${aws_vpc.vpc.ipv6_cidr_block}"
}

output "subnet_lan_id" {
  description = "LAN subnet ids"
  value = "${aws_subnet.lan.*.id}"
}

output "subnet_lan_arn" {
  description = "LAN subnet arns"
  value = "${aws_subnet.lan.*.arn}"
}

output "subnet_lan_cidr_block" {
  description = "VPC CIDR block"
  value = "${aws_subnet.lan.*.cidr_block}"
}

output "subnet_lan_ipv6_cidr_block" {
  description = "VPC IPv6 CIDR block"
  value = "${aws_subnet.lan.*.ipv6_cidr_block}"
}

output "subnet_dmz_id" {
  description = "DMZ subnet ids"
  value = "${aws_subnet.dmz.*.id}"
}

output "subnet_dmz_arn" {
  description = "DMZ subnet arns"
  value = "${aws_subnet.dmz.*.arn}"
}

output "subnet_dmz_cidr_block" {
  description = "VPC CIDR block"
  value = "${aws_subnet.dmz.*.cidr_block}"
}

output "subnet_dmz_ipv6_cidr_block" {
  description = "VPC IPv6 CIDR block"
  value = "${aws_subnet.dmz.*.ipv6_cidr_block}"
}

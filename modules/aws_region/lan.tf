resource "aws_subnet" "lan" {
  count                           = "${min(8, length(data.aws_availability_zones.azs.names))}"
  vpc_id                          = "${aws_vpc.vpc.id}"
  cidr_block                      = "${cidrsubnet(aws_vpc.vpc.cidr_block, 5, count.index * 4 + 1)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, count.index * 4 + 1)}"
  availability_zone               = "${element(data.aws_availability_zones.azs.names, count.index)}"
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = false
  tags = {
    Name = "lan.${element(data.aws_availability_zones.azs.names, count.index)}.${var.domain}"
  }
}

resource "aws_route_table" "lan" {
  count  = "${length(aws_subnet.lan)}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "lan.${element(data.aws_availability_zones.azs.names, count.index)}.${var.domain}"
  }
}

resource "aws_route_table_association" "lan" {
  count          = "${length(aws_subnet.lan)}"
  route_table_id = "${element(aws_route_table.lan, count.index).id}"
  subnet_id      = "${element(aws_subnet.lan, count.index).id}"
}

resource "aws_route" "nat" {
  count                  = "${length(aws_subnet.lan)}"
  route_table_id         = "${element(aws_route_table.lan, count.index).id}"
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = "${element(aws_network_interface.nat, count.index).id}"
}

resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route" "eigw" {
  count                       = "${length(aws_subnet.lan)}"
  route_table_id              = "${element(aws_route_table.lan, count.index).id}"
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = "${aws_egress_only_internet_gateway.eigw.id}"
}

resource "aws_vpc_endpoint_route_table_association" "s3_lan" {
  count           = "${length(aws_subnet.lan)}"
  route_table_id  = "${element(aws_route_table.lan, count.index).id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_lan" {
  count           = "${length(aws_subnet.lan)}"
  route_table_id  = "${element(aws_route_table.lan, count.index).id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}

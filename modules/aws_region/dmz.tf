resource "aws_subnet" "dmz" {
  count                           = "${min(8, length(data.aws_availability_zones.azs.names))}"
  vpc_id                          = "${aws_vpc.vpc.id}"
  cidr_block                      = "${cidrsubnet(aws_vpc.vpc.cidr_block, 5, count.index * 4)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, count.index * 4)}"
  availability_zone               = "${element(data.aws_availability_zones.azs.names, count.index)}"
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  tags = {
    Name = "dmz.${element(data.aws_availability_zones.azs.names, count.index)}.${var.domain}"
  }
}

resource "aws_route_table" "dmz" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "dmz.${var.region}.${var.domain}"
  }
}

resource "aws_route_table_association" "dmz" {
  count          = "${length(aws_subnet.dmz)}"
  route_table_id = "${aws_route_table.dmz.id}"
  subnet_id      = "${element(aws_subnet.dmz, count.index).id}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route" "igw" {
  route_table_id         = "${aws_route_table.dmz.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route" "igw6" {
  route_table_id              = "${aws_route_table.dmz.id}"
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.igw.id}"
}

resource "aws_vpc_endpoint_route_table_association" "s3_dmz" {
  route_table_id  = "${aws_route_table.dmz.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_dmz" {
  route_table_id  = "${aws_route_table.dmz.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}

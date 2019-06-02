resource "aws_network_interface" "nat" {
  count       = "${length(aws_subnet.dmz)}"
  private_ips = ["${cidrhost(element(aws_subnet.dmz, count.index).cidr_block, 4)}"]
  subnet_id   = "${element(aws_subnet.dmz, count.index).id}"
  tags = {
    Name = "natgw.${element(data.aws_availability_zones.azs.names, count.index)}.${var.domain}"
  }
}

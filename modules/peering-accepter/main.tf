resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = "${var.connection_id}"
  auto_accept   = true
}

resource "aws_route" "peer" {
  count                  = "${length(var.route_tables)}"
  route_table_id         = "${element(var.route_tables, count.index)}"
  destination_cidr_block = "${var.destination_cidr_block}"
  vpc_peering_connection_id = "${var.connection_id}"
}

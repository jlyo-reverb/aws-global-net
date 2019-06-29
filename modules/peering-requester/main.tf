resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = "${var.vpc_id}"
  peer_vpc_id = "${var.peer_vpc_id}"
  peer_region = "${var.peer_region}"
}

resource "aws_route" "peer" {
  count                     = "${length(var.route_tables)}"
  route_table_id            = "${element(var.route_tables, count.index)}"
  destination_cidr_block    = "${var.destination_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

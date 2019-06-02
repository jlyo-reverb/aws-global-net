output "connection_id" {
  description = "Peering connection ID"
  value = "${aws_vpc_peering_connection.peer.id}"
}

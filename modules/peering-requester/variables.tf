variable "vpc_id" {}
variable "peer_vpc_id" {}
variable "peer_region" {}
variable "destination_cidr_block" {}
variable "route_tables" {
  type = "list"
}

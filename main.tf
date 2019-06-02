data "external" "region_ids" {
  program = ["./external/region_ids"]
  query   = {}
}

locals {
  region_ids = "${data.external.region_ids.result}"
}

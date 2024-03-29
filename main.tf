// IP attachment to be added to seed node, and this is subsequently assigned as Harvester vip
// in the config.yaml
resource "random_password" "password" {
  length  = 16
  special = false
}

resource "random_password" "token" {
  length  = 16
  special = false
}

resource "equinix_metal_reserved_ip_block" "harvester_vip" {
  project_id = data.equinix_metal_project.project.project_id
  metro      = var.metro
  type       = "public_ipv4"
  quantity   = 1
}

resource "equinix_metal_device" "seed" {
  hostname         = "${var.hostname_prefix}-1"
  count            = var.node_count >= 1 && !var.spot_instance ? 1 : 0
  plan             = var.plan
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = var.billing_cylce
  project_id       = data.equinix_metal_project.project.project_id
  ipxe_script_url  = var.ipxe_script
  always_pxe       = "false"
  user_data        = templatefile("${path.module}/create.tpl", { version = var.harvester_version, password = random_password.password.result, token = random_password.token.result, vip = equinix_metal_reserved_ip_block.harvester_vip.network, hostname_prefix = var.hostname_prefix, ssh_key = var.ssh_key, count = "1" })
}

resource "equinix_metal_spot_market_request" "seed_spot_request" {
  count            = var.node_count >= 1 && var.spot_instance ? 1 : 0
  project_id       = data.equinix_metal_project.project.project_id
  max_bid_price    = var.max_bid_price
  facilities       = [var.facility]
  devices_min      = 1
  devices_max      = 1
  wait_for_devices = true

  instance_parameters {
    hostname         = "${var.hostname_prefix}-1"
    billing_cycle    = "hourly"
    operating_system = "custom_ipxe"
    ipxe_script_url  = var.ipxe_script
    plan             = var.plan
    userdata         = templatefile("${path.module}/create.tpl", { version = var.harvester_version, password = random_password.password.result, token = random_password.token.result, vip = equinix_metal_reserved_ip_block.harvester_vip.network, hostname_prefix = var.hostname_prefix, ssh_key = var.ssh_key, count = "1" })
  }
}

data "equinix_metal_spot_market_request" "seed_req" {
  count      = var.spot_instance ? 1 : 0
  request_id = equinix_metal_spot_market_request.seed_spot_request.0.id
}

resource "equinix_metal_ip_attachment" "first_address_assignment" {
  device_id     = var.spot_instance ? data.equinix_metal_spot_market_request.seed_req.0.device_ids[0] : equinix_metal_device.seed.0.id
  cidr_notation = join("/", [cidrhost(equinix_metal_reserved_ip_block.harvester_vip.cidr_notation, 0), "32"])
}

resource "equinix_metal_device" "join" {
  hostname         = "${var.hostname_prefix}-${count.index +2}"
  count            = var.spot_instance ? 0 : var.node_count -1
  plan             = var.plan
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = var.billing_cylce
  project_id       = data.equinix_metal_project.project.project_id
  ipxe_script_url  = var.ipxe_script
  always_pxe       = "false"
  user_data        = templatefile("${path.module}/join.tpl", { version = var.harvester_version, password = random_password.password.result, token = random_password.token.result, seed = equinix_metal_device.seed.0.access_public_ipv4,  hostname_prefix = var.hostname_prefix, ssh_key = var.ssh_key, count = "${count.index + 2}" })
}

resource "equinix_metal_spot_market_request" "join_spot_request" {
  count         = var.spot_instance ? var.node_count -1 : 0
  project_id    = data.equinix_metal_project.project.project_id
  max_bid_price = var.max_bid_price
  facilities    = [var.facility]
  devices_min   = 1
  devices_max   = 1

  instance_parameters {
    hostname         = "${var.hostname_prefix}-${count.index + 2}"
    billing_cycle    = "hourly"
    operating_system = "custom_ipxe"
    ipxe_script_url  = var.ipxe_script
    plan             = var.plan
    userdata         = templatefile("${path.module}/join.tpl", { version = var.harvester_version, password = random_password.password.result, token = random_password.token.result, seed = equinix_metal_reserved_ip_block.harvester_vip.network, hostname_prefix = var.hostname_prefix, ssh_key = var.ssh_key, count = "${count.index + 2}" })
  }
}

output "harvester_url" {
  value = "https://${equinix_metal_reserved_ip_block.harvester_vip.network}/"
}

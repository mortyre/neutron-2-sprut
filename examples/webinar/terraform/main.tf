# yaklass-test

terraform {
    required_providers {
        vkcs = {
            source  = "vk-cs/vkcs"
            version = "~> 0.7.1"
        }
    }
}

// ---- NETWORKING NEUTRON -----------------

resource "vkcs_networking_network" "webinar-loadbalancer-network" {
  name        = "webinar-loadbalancer-network"
  description = "webinar example network"
  sdn = "neutron"
}

resource "vkcs_networking_subnet" "webinar-loadbalancer-subnet" {
  name       = "webinar-loadbalancer-subnet"
  network_id = vkcs_networking_network.webinar-loadbalancer-network.id
  cidr       = "10.70.70.0/24"
  sdn = "neutron"
}

resource "vkcs_networking_router" "webinar-router" {
  name = "webinar-router"
  # Connect router to Internet
  external_network_id = data.vkcs_networking_network.extnet.id
  tags                = ["webinar"]
  sdn = "neutron"
}

resource "vkcs_networking_router_interface" "webinar-lbnet-router-interface" {
  router_id = vkcs_networking_router.webinar-router.id
  subnet_id = vkcs_networking_subnet.webinar-loadbalancer-subnet.id
  sdn = "neutron"
}

resource "vkcs_networking_network" "webinar-vpn-network" {
  name        = "webinar-vpn-network"
  description = "webinar vpn example network"
  sdn = "neutron"
}

resource "vkcs_networking_subnet" "webinar-vpn-subnet" {
  name       = "webinar-vpn-subnet"
  network_id = vkcs_networking_network.webinar-vpn-network.id
  cidr       = "10.20.0.0/24"
  sdn = "neutron"
}

resource "vkcs_networking_router_interface" "webinar-vpnnet-router-interface" {
  router_id = vkcs_networking_router.webinar-router.id
  subnet_id = vkcs_networking_subnet.webinar-vpn-subnet.id
  sdn = "neutron"
}

resource "vkcs_networking_secgroup" "webinar-secgroup-http" {
  name        = "webinar-secgroup-http"
  description = "secgroup from webinar example"
  sdn = "neutron"
}

resource "vkcs_networking_secgroup_rule" "webinar-secgroup-rule" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_max    = 2379
  port_range_min    = 80
  security_group_id = "${vkcs_networking_secgroup.webinar-secgroup-http.id}"
  sdn = "neutron"
}

// ---------- LOADBALANCER ---------

resource "vkcs_lb_loadbalancer" "webinar-loadbalancer" {
  name          = "webinar-loadbalancer"
  description   = "balancer for testing copying neutron to sprut"
  vip_subnet_id = vkcs_networking_subnet.webinar-loadbalancer-subnet.id
  vip_address = "10.70.70.11"
}

resource "vkcs_lb_listener" "webinar-loadbalancer-http-listener" {
  name            = "webinar-loadbalancer-http-listener"
  description     = "Listener for resources/datasources testing"
  loadbalancer_id = vkcs_lb_loadbalancer.webinar-loadbalancer.id
  protocol        = "HTTP"
  protocol_port   = 80
}

resource "vkcs_networking_floatingip" "associated_fip" {
  pool    = "ext-net"
  port_id = vkcs_lb_loadbalancer.webinar-loadbalancer.vip_port_id
}


resource "vkcs_lb_pool" "webinar-loadbalancer-http-pool" {
  name        = "webinar-loadbalancer-http-pool"
  description = "Pool for http member/members testing"
  listener_id = vkcs_lb_listener.webinar-loadbalancer-http-listener.id
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
}

resource "vkcs_lb_monitor" "webinar-loadbalancer-healthchecker" {
	name        = "webinar-loadbalancer-healthchecker"
	pool_id     = vkcs_lb_pool.webinar-loadbalancer-http-pool.id
	type        = "HTTP"
	delay       = 20
	timeout     = 10
	max_retries = 5
}

resource "vkcs_lb_members" "webinar-nginx-members" {
  pool_id = vkcs_lb_pool.webinar-loadbalancer-http-pool.id

  dynamic "member" {
    for_each = vkcs_compute_instance.webinar-nginx-server-vm
    content {
      address       = member.value.access_ip_v4
      protocol_port = 80
    }
  }
}

data "vkcs_networking_secgroup" "all" {
  name = "all"
  sdn = "neutron"
}

data "vkcs_networking_secgroup" "default" {
  name = "default"
  sdn = "neutron"
}

// ------------------VPNs --------------------------

resource "vkcs_vpnaas_service" "webinar-vpn-service" {
  name      = "webinar-vpn-service"

  # See the argument description and check vkcs_networks_sdn datasource output to figure out
  # what type of router you should use in certain case (vkcs_networking_router or vkcs_dc_router)
  router_id = vkcs_networking_router.webinar-router.id
}

resource "vkcs_vpnaas_ipsec_policy" "webinar-ipsec-policy" {
  name        = "webinar-ipsec-policy"
  description = "Policy that restricts remote working users to connect to our data ceneter over VPN"
  lifetime {
    units = "seconds"
    value = 7200
  }
  encryption_algorithm = "aes-256"
  auth_algorithm = "sha256"
  encapsulation_mode = "tunnel"
  pfs = "group14"
  transform_protocol = "esp"
  sdn = "neutron"
}

resource "vkcs_vpnaas_ike_policy" "webinar-ike-policy" {
  name           = "webinar-ike-policy"
  description    = "Policy that restricts remote working users to connect to our data ceneter over VPN"
  auth_algorithm = "sha256"
  encryption_algorithm = "aes-256"
  ike_version = "v2"
  lifetime {
    units = "seconds"
    value = 14400
  }
  pfs = "group14"
  phase1_negotiation_mode = "main"
  sdn = "neutron"
}

resource "vkcs_vpnaas_endpoint_group" "webinar-remote-endpoint-group" {
  name = "webinar-remote-endpoint-group"
  type = "cidr"
  endpoints = [
    "10.10.0.0/24"
  ]
  sdn = "neutron"
}

resource "vkcs_vpnaas_endpoint_group" "webinar-local-endpoint-group" {
  name = "webinar-local-endpoint-group"
  type      = "subnet"
  endpoints = [vkcs_networking_subnet.webinar-vpn-subnet.id]
  sdn = "neutron"
}

resource "vkcs_vpnaas_site_connection" "webinar-ipsec-to-arch" {
  name              = "webinar-ipsec-to-arch"
  ikepolicy_id      = vkcs_vpnaas_ike_policy.webinar-ike-policy.id
  ipsecpolicy_id    = vkcs_vpnaas_ipsec_policy.webinar-ipsec-policy.id
  vpnservice_id     = vkcs_vpnaas_service.webinar-vpn-service.id
  psk               = "e98d^5nU8Nh0j0L6"
  peer_address      = "89.208.221.86"
  peer_id           = "89.208.221.86"
  local_ep_group_id = vkcs_vpnaas_endpoint_group.webinar-local-endpoint-group.id
  peer_ep_group_id  = vkcs_vpnaas_endpoint_group.webinar-remote-endpoint-group.id
  dpd {
    action   = "hold"
    timeout  = 120
    interval = 30
  }
  depends_on = [vkcs_networking_router_interface.webinar-vpnnet-router-interface]
  sdn = "neutron"
}

// ----------------------- VIRTUAL MACHINES ------------------------

data "vkcs_images_image" "ubuntu" {
  # Both arguments are required to search an actual image provided by VKCS.
  visibility = "public"
  default    = true
  # Use properties to distinguish between available images.
  properties = {
    mcs_os_distro  = "ubuntu"
    mcs_os_version = "22.04"
  }
}

// -----------------VIRTUAL MACHINES------------------

// ----------------- NGINX SERVER VMS ---------------
resource "vkcs_compute_instance" "webinar-nginx-server-vm" {
  count = var.instance_count # Add this line, define `instance_count` in your variables.tf

  name = "${var.nginx-vm-instance-name-prefix}-${count.index}" # Modify this line

  security_group_ids = [ vkcs_networking_secgroup.webinar-secgroup-http.id, data.vkcs_networking_secgroup.default.id]
  # AZ and flavor are mandatory
  availability_zone = "ME1"
  flavor_name       = "Basic-1-2-20"
  # Use block_device to specify instance disk to get full control
  # of it in the future
  block_device {
    source_type      = "image"
    uuid             = data.vkcs_images_image.ubuntu.id
    destination_type = "volume"
    volume_size      = 14
  //  volume_type      = "ceph-ssd"
    # Must be set to delete volume after instance deletion
    # Otherwise you get "orphaned" volume with terraform
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.webinar-loadbalancer-network.id
  }

  # ensure it is attached to a router before creating of the instance
  depends_on = [
    vkcs_networking_router_interface.webinar-vpnnet-router-interface
  ]
}

// -------------------- VPN VM ------------------------------
resource "vkcs_compute_instance" "webinar-check-vpn-vm" {
  name = "webinar-check-vpn-vm" # Modify this line

  security_group_ids = [data.vkcs_networking_secgroup.default.id, data.vkcs_networking_secgroup.all.id]
  # AZ and flavor are mandatory
  availability_zone = "ME1"
  flavor_name       = "Basic-1-2-20"
  # Use block_device to specify instance disk to get full control
  # of it in the future
  block_device {
    source_type      = "image"
    uuid             = data.vkcs_images_image.ubuntu.id
    destination_type = "volume"
    volume_size      = 14
  //  volume_type      = "ceph-ssd"
    # Must be set to delete volume after instance deletion
    # Otherwise you get "orphaned" volume with terraform
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.webinar-vpn-network.id
  }

  # ensure it is attached to a router before creating of the instance
  depends_on = [
    vkcs_networking_router_interface.webinar-vpnnet-router-interface
  ]
}


// ----------------- VARIABLES ------------------------

variable "instance_count" {
  description = "The number of instances to create."
  type        = number
  default = 2
}

variable "nginx-vm-instance-name-prefix" {
  description = "Prefix for the instance names."
  type        = string
  default = "webinar-nginx-server-vm"
}

data "vkcs_networking_network" "extnet" {
  name = "ext-net"
  sdn = "neutron"
}
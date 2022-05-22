provider "aviatrix" {
  username      = var.username
  password      = var.password
  controller_ip = var.controller_ip
}

# Generate random pre-shared keys and tunnel IPs
resource "random_password" "fr_va_key" {
  count            = 4
  length           = 32
  special          = true
  override_special = "._"
}

resource "random_integer" "tun_gw_ip" {
  min = 1
  max = 63
}

resource "random_integer" "tun_hagw_ip" {
  min = 1
  max = 63
}


# Native peerings for ActiveMesh links
resource "aviatrix_aws_peer" "transit_peering" {
  account_name1 = var.tr_account_name
  account_name2 = var.mg_account_name
  vpc_id1       = var.tr_transit_vpc_id
  vpc_id2       = var.mg_transit_vpc_id
  vpc_reg1      = var.tr_region
  vpc_reg2      = var.mg_region
  rtb_list1 = [
    var.tr_gw_peering_rt,
  ]
  rtb_list2 = [
    var.mg_gw_peering_rt,
  ]
}


####################################################################
## AS to AM connection over native peering: OR >> OR
####################################################################

resource "aviatrix_transit_external_device_conn" "Transit-to-managed-1" {
  vpc_id             = var.tr_transit_vpc_id
  connection_name    = "Transit-To-${var.egde_loc}-EDGE-1"
  gw_name            = var.tr_gw_name
  remote_gateway_ip  = var.mg_gw_private_ip
  pre_shared_key     = "${random_password.fr_va_key[0].result},${random_password.fr_va_key[1].result}"
  custom_algorithms  = false
  connection_type    = "bgp"
  bgp_local_as_num   = var.tr_asn
  bgp_remote_as_num  = var.mg_asn
  local_tunnel_cidr  = "${cidrhost(cidrsubnet("169.254.11.0/24", 6, random_integer.tun_gw_ip.result), 1)}/30"
  remote_tunnel_cidr = "${cidrhost(cidrsubnet("169.254.11.0/24", 6, random_integer.tun_gw_ip.result), 2)}/30"

  #manual_bgp_advertised_cidrs = var.tr_summaries

  depends_on = [aviatrix_aws_peer.transit_peering]
}

# resource "aviatrix_transit_external_device_conn" "Transit-to-managed-2" {
#   vpc_id             = var.tr_transit_vpc_id
#   connection_name    = "Transit-To-${var.egde_loc}-EDGE-2"
#   gw_name            = var.tr_gw_name
#   remote_gateway_ip  = var.mg_hagw_private_ip
#   pre_shared_key     = "${random_password.fr_va_key[2].result},${random_password.fr_va_key[3].result}"
#   custom_algorithms  = false
#   connection_type    = "bgp"
#   bgp_local_as_num   = var.tr_asn
#   bgp_remote_as_num  = var.mg_asn
#   local_tunnel_cidr  = "${cidrhost(cidrsubnet("169.254.13.0/24", 6, random_integer.tun_gw_ip.result), 1)}/30"
#   remote_tunnel_cidr = "${cidrhost(cidrsubnet("169.254.13.0/24", 6, random_integer.tun_gw_ip.result), 2)}/30"

#   manual_bgp_advertised_cidrs = var.tr_summaries

#   depends_on = [aviatrix_aws_peer.transit_peering]
# }

resource "aviatrix_transit_external_device_conn" "managed-to-Transit-1" {
  vpc_id             = var.mg_transit_vpc_id
  connection_name    = "${var.egde_loc}-EDGE-To-Transit-1"
  gw_name            = var.mg_gw_name
  remote_gateway_ip  = var.tr_gw_private_ip
  pre_shared_key     = "${random_password.fr_va_key[0].result},${random_password.fr_va_key[2].result}"
  custom_algorithms  = false
  connection_type    = "bgp"
  bgp_local_as_num   = var.mg_asn
  bgp_remote_as_num  = var.tr_asn
  local_tunnel_cidr  = "${cidrhost(cidrsubnet("169.254.11.0/24", 6, random_integer.tun_gw_ip.result), 2)}/30,${cidrhost(cidrsubnet("169.254.13.0/24", 6, random_integer.tun_gw_ip.result), 2)}/30"
  remote_tunnel_cidr = "${cidrhost(cidrsubnet("169.254.11.0/24", 6, random_integer.tun_gw_ip.result), 1)}/30,${cidrhost(cidrsubnet("169.254.13.0/24", 6, random_integer.tun_gw_ip.result), 1)}/30"

  #manual_bgp_advertised_cidrs = var.mg_summaries

  depends_on = [aviatrix_aws_peer.transit_peering]
}

# resource "aviatrix_transit_external_device_conn" "managed-to-Transit-2" {
#   vpc_id             = var.mg_transit_vpc_id
#   connection_name    = "${var.egde_loc}-EDGE-To-Transit-2"
#   gw_name            = var.mg_gw_name
#   remote_gateway_ip  = var.tr_hagw_private_ip
#   pre_shared_key     = "${random_password.fr_va_key[1].result},${random_password.fr_va_key[3].result}"
#   custom_algorithms  = false
#   connection_type    = "bgp"
#   bgp_local_as_num   = var.mg_asn
#   bgp_remote_as_num  = var.tr_asn
#   local_tunnel_cidr  = "${cidrhost(cidrsubnet("169.254.12.0/24", 6, random_integer.tun_hagw_ip.result), 2)}/30,${cidrhost(cidrsubnet("169.254.14.0/24", 6, random_integer.tun_hagw_ip.result), 2)}/30"
#   remote_tunnel_cidr = "${cidrhost(cidrsubnet("169.254.12.0/24", 6, random_integer.tun_hagw_ip.result), 1)}/30,${cidrhost(cidrsubnet("169.254.14.0/24", 6, random_integer.tun_hagw_ip.result), 1)}/30"

#   #manual_bgp_advertised_cidrs = var.mg_summaries

#   depends_on = [aviatrix_aws_peer.transit_peering]
# }

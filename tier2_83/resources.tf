resource "citrixadc_nsfeature" "nsfeature" {
    wl = true
    lb = true
    ch = true
}

resource "citrixadc_nsmode" "nsmode" {
    fr = true
    l3 = true
    edge = true
    usnip = true
}

resource "citrixadc_nstcpprofile" "tcpprofile1" {
    name = "tcpprofile1"
    mss = 1330
}

resource "citrixadc_vlan" "vlan40" {
    vlanid = 40
}

resource "citrixadc_nsip" "nsip68" {
    ipaddress = "68.1.1.21"
    netmask = "255.255.255.0"
    vserver = "DISABLED"
}

resource "citrixadc_vlan_interface_binding" "if_bind40" {
    vlanid = citrixadc_vlan.vlan40.vlanid
    ifnum = "1/2"
}

resource "citrixadc_vlan_nsip_binding" "ip_bind40" {
    vlanid = citrixadc_vlan.vlan40.vlanid
    ipaddress = citrixadc_nsip.nsip68.ipaddress
    netmask = "255.255.255.0"
}

resource "citrixadc_vlan" "vlan50" {
    vlanid = 50
}

resource "citrixadc_nsip" "nsip67" {
    ipaddress = "67.1.1.21"
    netmask = "255.255.255.0"
    vserver = "DISABLED"
}

resource "citrixadc_vlan_interface_binding" "if_bind50" {
    vlanid = citrixadc_vlan.vlan50.vlanid
    ifnum = "1/3"
}

resource "citrixadc_vlan_nsip_binding" "ip_bind50" {
    vlanid = citrixadc_vlan.vlan50.vlanid
    ipaddress = citrixadc_nsip.nsip67.ipaddress
    netmask = "255.255.255.0"
}

resource "citrixadc_vlan" "vlan60" {
    vlanid = 60
}

resource "citrixadc_nsip" "nsip76" {
    ipaddress = "76.1.1.21"
    netmask = "255.255.255.0"
    vserver = "DISABLED"
}

resource "citrixadc_vlan_interface_binding" "if_bind60" {
    vlanid = citrixadc_vlan.vlan60.vlanid
    ifnum = "1/1"
}

resource "citrixadc_vlan_nsip_binding" "ip_bind60" {
    vlanid = citrixadc_vlan.vlan60.vlanid
    ipaddress = citrixadc_nsip.nsip76.ipaddress
    netmask = "255.255.255.0"
}

resource "citrixadc_nsip" "vip" {
    ipaddress = "66.1.1.100"
    netmask = "255.255.255.255"
    type = "VIP"
    arp = "DISABLED"
}

resource "citrixadc_iptunnel" "tun0" {
    name = "tun0"
    remote = "66.1.1.10"
    remotesubnetmask = "255.255.255.255"
    local = "*"
}

resource "citrixadc_iptunnel" "tun1" {
    name = "tun1"
    remote = "66.1.1.11"
    remotesubnetmask = "255.255.255.255"
    local = "*"
}

resource "citrixadc_service" "s1" {
    servicetype = "TCP"
    name = "s1"
    ipaddress = "68.1.1.26"
    ip = "68.1.1.26"
    port = "65535"
}

resource "citrixadc_service" "s2" {
    servicetype = "TCP"
    name = "s2"
    ipaddress = "68.1.1.24"
    ip = "68.1.1.24"
    port = "65535"
}

resource "citrixadc_lbvserver" "lb1" {
  ipv46       = "66.1.1.100"
  name        = "lb1"
  port        = 65535
  servicetype = "TCP"
  tcpprofilename = citrixadc_nstcpprofile.tcpprofile1.name

  depends_on = [citrixadc_nsip.vip]
}

resource "citrixadc_lbvserver_service_binding" "lbbind" {
  name = citrixadc_lbvserver.lb1.name
  servicename = citrixadc_service.s1.name
  weight = 1
}

resource "citrixadc_route" "route1" {
  depends_on = [citrixadc_nsip.nsip67]
  network    = "60.1.1.0"
  netmask    = "255.255.255.0"
  gateway    = "67.1.1.100"
}

resource "citrixadc_route" "route2" {
  depends_on = [citrixadc_nsip.nsip76]
  network    = "66.1.1.0"
  netmask    = "255.255.255.0"
  gateway    = "76.1.1.24"
}

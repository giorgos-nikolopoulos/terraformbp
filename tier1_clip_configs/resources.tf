resource "citrixadc_nsfeature" "nsfeature" {
    wl = true
    lb = true
    sp = true
    bgp = true
}

resource "citrixadc_nsmode" "nsmode" {
    fr = true
    l3 = true
    edge = true
    usnip = true
}

resource "citrixadc_vlan" "vlan30" {
    vlanid = 30
}

resource "citrixadc_nsip" "snip_owner0" {
    ipaddress = "66.1.1.10"
    netmask = "255.255.255.0"
    vserver = "DISABLED"
    ownernode = "0"
}

resource "citrixadc_nsip" "snip_owner1" {
    ipaddress = "66.1.1.11"
    netmask = "255.255.255.0"
    vserver = "DISABLED"
    ownernode = "1"
}

resource "citrixadc_vlan_interface_binding" "if_bind1" {
    vlanid = citrixadc_vlan.vlan30.vlanid
    ifnum = "0/1/2"
}

resource "citrixadc_vlan_interface_binding" "if_bind2" {
    vlanid = citrixadc_vlan.vlan30.vlanid
    ifnum = "1/1/2"
}

resource "citrixadc_vlan_nsip_binding" "ip_bind" {
    vlanid = citrixadc_vlan.vlan30.vlanid
    ipaddress = citrixadc_nsip.snip_owner0.ipaddress
    netmask = "255.255.255.0"
}

resource "citrixadc_nsip" "vip" {
    ipaddress = "66.1.1.100"
    netmask = "255.255.255.255"
    type = "VIP"
    snmp = "DISABLED"
    hostroute = "ENABLED"
    vserverrhilevel = "NONE"
}

resource "citrixadc_service" "s1" {
    servicetype = "ANY"
    name = "s1"
    ipaddress = "76.1.1.20"
    ip = "76.1.1.20"
    port = "65535"
    usip = "YES"
}

resource "citrixadc_service" "s2" {
    servicetype = "ANY"
    name = "s2"
    ipaddress = "76.1.1.21"
    ip = "76.1.1.21"
    port = "65535"
    usip = "YES"
}

resource "citrixadc_lbparameter" "lbparameter" {
    lbhashalgorithm = "JARH"
}

resource "citrixadc_lbvserver" "v1" {
  ipv46       = citrixadc_nsip.vip.ipaddress
  name        = "v1"
  port        = 65535
  servicetype = "ANY"
  persistencetype = "NONE"
  lbmethod = "SOURCEIPHASH"
  m = "IPTUNNEL"
  sessionless = "ENABLED"
  clttimeout = 120
}

resource "citrixadc_lbvserver_service_binding" "lbbind1" {
  name = citrixadc_lbvserver.v1.name
  servicename = citrixadc_service.s1.name
  weight = 1
}

resource "citrixadc_lbvserver_service_binding" "lbbind2" {
  name = citrixadc_lbvserver.v1.name
  servicename = citrixadc_service.s2.name
  weight = 1
}

resource "citrixadc_route" "route1" {
  depends_on = [citrixadc_nsip.snip_owner0, citrixadc_nsip.snip_owner1]
  network    = "76.1.1.0"
  netmask    = "255.255.255.0"
  gateway    = "66.1.1.24"
  ownergroup = "ng1"
}

resource "citrixadc_route" "route2" {
  depends_on = [citrixadc_nsip.snip_owner0, citrixadc_nsip.snip_owner1]
  network    = "76.1.1.0"
  netmask    = "255.255.255.0"
  gateway    = "66.1.1.24"
  ownergroup = "ng2"
}

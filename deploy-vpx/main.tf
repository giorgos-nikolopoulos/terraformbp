variable "vsphere_ip" {
  default = "10.217.100.183"
}
variable "vsphere_username" {
  default = "administrator@vsphere.local"
}
variable "vsphere_password" {
}
variable "datacenter_name" {
  default = "Datacenter"
}
variable "datastore_name" {
  default = "datastore1-h154-RAID0"
}
variable "resource_pool_name" {
  default = "CNN_Cluster/Resources"
}
variable "resource_host" {
  default = "10.217.100.154"
}
variable "network_name" {
  default = "common|default|Lab-VLAN1202"
}
variable "virtual_machine_name" {
}
variable "remote_vpx_ovf_path" {
  default = "http://10.217.100.109/vra/monday-manual-deploy-working.ovf"
}
variable "vpx_nsip" {
}
variable "memory" {
  default = 2048 
}
variable "num_cpus" {
  default = 2 
}

######################################################

provider "vsphere" {
  user           = var.vsphere_username
  password       = var.vsphere_password
  vsphere_server = var.vsphere_ip

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

######################################################

data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# https://github.com/hashicorp/terraform-provider-vsphere/issues/262#issuecomment-348644869
# Every cluster will have a default `Resources` resource_pool
data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.resource_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "citrixVPX" {
  name                       = var.virtual_machine_name
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  host_system_id             = data.vsphere_host.host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  datacenter_id              = data.vsphere_datacenter.dc.id

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  scsi_type = "lsilogic"
  num_cpus  = var.num_cpus
  memory    = var.memory

  ovf_deploy {
    remote_ovf_url            = var.remote_vpx_ovf_path
    allow_unverified_ssl_cert = true
  }
  vapp {
    properties = {
      "eth0.ipAddress" : var.vpx_nsip
    }
  }
}

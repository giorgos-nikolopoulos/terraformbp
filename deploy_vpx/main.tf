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
variable "eth0_network_name" {
  default = "common|default|Lab-VLAN1202"
}
variable "eth1_network_name" {
  default = "h157-vsw0-VLAN1201"
}

variable "virtual_machine_name" {
  type = list(string)
}
variable "remote_vpx_ovf_path" {
  default = "http://10.217.100.109/vra/monday-manual-deploy-working.ovf"
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

data "vsphere_network" "eth0" {
  name          = var.eth0_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "eth1" {
  name          = var.eth1_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine
resource "vsphere_virtual_machine" "citrixVPX" {
  count            = length(var.virtual_machine_name)
  name             = element(var.virtual_machine_name, count.index)
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  # folder - (Optional) The path to the folder to put this virtual machine in, relative to the datacenter that the resource pool is in.
  # folder = "test-vapp"
  host_system_id             = data.vsphere_host.host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  datacenter_id              = data.vsphere_datacenter.dc.id

  network_interface {
    network_id = data.vsphere_network.eth0.id
    # adapter_type = "e1000"

    # adapter_type - The network interface type. Can be one of e1000, e1000e, or vmxnet3. Default: vmxnet3.
    # ovf_mapping - (Optional) Specifies which OVF NIC the network_interface should be associated with. Only applies at creation and only when deploying from an OVF source.
  }

  #  network_interface {
  #    network_id = data.vsphere_network.eth1.id
  #    # adapter_type - The network interface type. Can be one of e1000, e1000e, or vmxnet3. Default: vmxnet3.
  #    # ovf_mapping - (Optional) Specifies which OVF NIC the network_interface should be associated with. Only applies at creation and only when deploying from an OVF source.
  #  }

  # scsi_type - (Optional) The type of SCSI bus this virtual machine will have. Can be one of lsilogic (LSI Logic Parallel), lsilogic-sas (LSI Logic SAS) or pvscsi (VMware Paravirtual). Defualt: pvscsi.
  scsi_type = "lsilogic"

  # num_cpus - (Optional) The total number of virtual processor cores to assign to this virtual machine. Default: 1.
  # num_cores_per_socket - (Optional) The number of cores per socket in this virtual machine. The number of vCPUs on the virtual machine will be num_cpus divided by num_cores_per_socket. If specified, the value supplied to num_cpus must be evenly divisible by this value. Default: 1.
  # cpu_hot_add_enabled - (Optional) Allow CPUs to be added to this virtual machine while it is running.
  # cpu_hot_remove_enabled - (Optional) Allow CPUs to be removed to this virtual machine while it is running.
  # memory - (Optional) The size of the virtual machine's memory, in MB. Default: 1024 (1 GB).
  # memory_hot_add_enabled - (Optional) Allow memory to be added to this virtual machine while it is running.
  num_cpus = var.num_cpus
  memory   = var.memory # in MBs


  # https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine#creating-vm-from-deploying-a-ovfova-template
  ovf_deploy {
    remote_ovf_url           = var.remote_vpx_ovf_path
    enable_hidden_properties = true
    # local_ovf_path = var.local_vpx_ovf_path
    # ip_allocation_policy = "STATIC_IPPOOL" # <-- This did not work
    # ip_protocol = "IPV4"
    allow_unverified_ssl_cert = true

    # ip_allocation_policy - (Optional) The IP allocation policy.
    # ip_protocol - (Optional) The IP protocol.
    # disk_provisioning - (Optional) The disk provisioning. If set, all the disks in the deployed OVF will have the same specified disk type (accepted values {thin, flat, thick, sameAsSource}).
    # deployment_option - (Optional) The key of the chosen deployment option. If empty, the default option is chosen.
    # ovf_network_map - (Optional) The mapping of name of network identifiers from the ovf descriptor to network UUID in the VI infrastructure.
    # allow_unverified_ssl_cert - (Optional) Allow unverified ssl certificates while deploying ovf/ova from url. Defaults true.
  }

  # https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine#using-vapp-properties-to-supply-ovfova-configuration
  # vapp {
  #   properties = {
  #     "eth0.ipAddress" : var.vpx_nsip
  #   }
  # }
  #   vapp {
  #     properties = {
  #       "eth0.ipAddress" = "$${autoip:common|default|Lab-VLAN1202}"
  #       "eth0.gatewayAddress” = "$${gateway:common|default|Lab-VLAN1202}"
  #       "eth0.connectivityType" = "mgmt"
  #       "eth0.subnetMask" = "$${netmask:common|default|Lab-VLAN1202}"
  # }
  # }
  provisioner "local-exec" {
    command = format("pwsh ./module.ps1 -vmname %s -vserverip %s -vserveruser %s -vserverpass '%s' -networkname '%s'",
      element(var.virtual_machine_name, count.index),
      var.vsphere_ip,
      var.vsphere_username,
      var.vsphere_password,
      var.eth0_network_name
    )
  }
}


# TODO: Attribute guest_ip_addresses may not have been populated at the time of `terraform apply`
# TODO: Need to find a way

# output "nsip" {
#   value = vsphere_virtual_machine.citrixVPX.*.guest_ip_addresses.0
# }
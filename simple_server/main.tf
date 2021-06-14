provider "citrixadc" {
  endpoint = format("http://%s", var.nsip)
  password = var.password
}

terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
  }
}

variable "password" {
  description = "Password for ADC"
}
variable "nsip" {
  description = "NSIP for ADC"
}

resource "citrixadc_server" "test_server" {
  name      = "test_server"
  ipaddress = "192.168.2.2"
}

provider "citrixadc" {
  endpoint = "http://10.217.107.133"
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

resource "citrixadc_server" "test_server" {
  name      = "test_server"
  ipaddress = "192.168.2.2"
}

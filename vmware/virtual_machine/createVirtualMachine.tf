#################################################################
# Module to deploy VM with  specified applications installed:
#
# Version: 1.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017.
#
#################################################################

#########################################################
# Define the variables
#########################################################
variable "name" {
  description = "Name of the Virtual Machine"
}

variable "folder" {
  description = "Target vSphere folder for Virtual Machine"
  default     = ""
}

variable "datacenter" {
  description = "Target vSphere datacenter for Virtual Machine creation"
  default     = ""
}

variable "vcpu" {
  description = "Number of Virtual CPU for the Virtual Machine"
  default     = 1
}

variable "memory" {
  description = "Memory for Virtual Machine in MBs"
  default     = 1024
}

variable "cluster" {
  description = "Target vSphere Cluster to host the Virtual Machine"
  default     = ""
}

variable "dns_suffix" {
  description = "Name resolution suffix for the virtual network adapter"
  default     = ""
}

variable "primary_dns_server" {
  description = "Primary DNS server for the virtual network adapter"
  default     = "8.8.8.8"
}

variable "secondary_dns_server" {
  description = "Secondary DNS server for the virtual network adapter"
  default     = "8.8.4.4"
}

variable "network_label" {
  description = "vSphere Port Group or Network label for Virtual Machine's vNIC"
}

variable "ipv4_address" {
  description = "IPv4 address for vNIC configuration"
}

variable "ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "ipv4_prefix_length" {
  description = "IPv4 Prefix length for vNIC configuration"
}

variable "storage" {
  description = "Data store or storage cluster name for target VMs disks"
  default     = ""
}

variable "vm_template" {
  description = "Source VM or Template label for cloning"
}

variable "ssh_user" {
  description = "The user for ssh connection"
  default     = "root"
}

variable "camc_private_ssh_key" {
  description = "The base64 encoded private key for ssh connection"
  default     = ""
}

variable "user_public_key" {
  description = "User-provided public SSH key used to connect to the virtual machine"
  default     = "None"
}

variable "module_script" {
  description = "The script to install applications"  
  default     = "files/default.sh"	
}

variable "module_script_variables" {
  description = "The variables for script to install applications"
  default     = ""
}

variable "module_custom_commands" {
  description = "The extra commands needed after application installation"
  default     = "sleep 1"
}
variable "remove_camc_public_key" {
  description = "The indicator to remove camc public key or not"
  default     = "false"
}

##############################################################
# Create Virtual Machine
##############################################################
resource "vsphere_virtual_machine" "vm" {
  name       = "${var.name}"
  folder     = "${var.folder}"
  datacenter = "${var.datacenter}"
  vcpu       = "${var.vcpu}"
  memory       = "${var.memory}"
  cluster      = "${var.cluster}"
  dns_suffixes = ["${var.dns_suffix}"]
  dns_servers  = ["${var.primary_dns_server}","${var.secondary_dns_server}"]
  network_interface {
    label              = "${var.network_label}"
    ipv4_gateway       = "${var.ipv4_gateway}"
    ipv4_address       = "${var.ipv4_address}"
    ipv4_prefix_length = "${var.ipv4_prefix_length}"
  }
  
  disk {
    datastore = "${var.storage}"
    template  = "${var.vm_template}"
    type      = "thin"
  }

  # Specify the ssh connection
  connection {
    user        = "${var.ssh_user}"
    private_key = "${base64decode(var.camc_private_ssh_key)}"
    host        = "${self.network_interface.0.ipv4_address}"
  }

  # Create the installation script
  provisioner "file" {
    source      = "${path.module}/${var.module_script}"
    destination = "installation.sh"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x installation.sh",
      "bash installation.sh ${var.module_script_variables}",
      "bach -c 'mkdir -p .ssh; if [ ! -f .ssh/authorized_keys ]; then touch .ssh/authorized_keys; chmod 600 .ssh/authorized_keys; fi'",
      "bash -c 'if [ \"${var.remove_camc_public_key}\" == \"true\" ] ; then if [ \"${var.user_public_key}\" != \"None\" ] ; then echo \"${var.user_public_key}\" | tee $HOME/.ssh/authorized_keys; fi; fi'",
      "${var.module_custom_commands}"
    ]
  }
}

##############################################################
# Output
##############################################################
output "ip" {
    value = "${vsphere_virtual_machine.vm.network_interface.0.ipv4_address}"    
}

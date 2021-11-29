terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

provider "openstack" {
  user_name   = var.auth_data.user_name
  tenant_name = var.openstack_provider.tenant_name
  password    = var.auth_data.password
  auth_url    = var.openstack_provider.auth_url
}



# Define networking_secgroup and rules for them

resource "openstack_networking_secgroup_v2" "terraform_monitoring_server" {
  name        = "terraform_monitoring_server"
  description = "Created by Terraform. Do not use or manage manually."
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.terraform_monitoring_server.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9090
  port_range_max    = 9090
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.terraform_monitoring_server.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_3" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8500
  port_range_max    = 8500
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.terraform_monitoring_server.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3000
  port_range_max    = 3000
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.terraform_monitoring_server.id}"
}

resource "openstack_networking_secgroup_v2" "terraform_ALL" {
  name        = "terraform_ALL"
  description = "Created by Terraform. Do not use or manage manually."
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_5" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.horovod_network.network_subnet_range
  security_group_id = "${openstack_networking_secgroup_v2.terraform_ALL.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_6" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.horovod_network.network_subnet_range
  security_group_id = "${openstack_networking_secgroup_v2.terraform_ALL.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_7" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = var.horovod_network.network_subnet_range
  security_group_id = "${openstack_networking_secgroup_v2.terraform_ALL.id}"
}

resource "openstack_networking_secgroup_v2" "terraform_horovod_master" {
  name        = "terraform_horovod_master"
  description = "Created by Terraform. Do not use or manage manually."
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_8" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.terraform_horovod_master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_9" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8888
  port_range_max    = 8888
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.terraform_horovod_master.id}"
}


# Define compute instances and run Ansible command after provisioning and boot

resource "openstack_compute_instance_v2" "monitoring_server" {
  name            = var.monitoring_server_node.name
  image_id        = var.monitoring_server_node.image_id
  flavor_name     = var.monitoring_server_node.flavor_name
  key_pair        = var.monitoring_server_node.key_pair
  security_groups = ["default", "${openstack_networking_secgroup_v2.terraform_monitoring_server.name}"]
  
  provisioner "local-exec" {
    working_dir = "./"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_RETRIES=10 sleep 30 && ansible-playbook -i '${self.access_ip_v4},' ../monitoring_server.yaml --extra-vars \"PROMETHEUS_IP=${self.access_ip_v4} NODE_NAME=Monitoring_server \" "
  }
}

resource "openstack_compute_instance_v2" "horovod_master" {
  name            = var.horovod_master_node.name
  image_id        = var.horovod_master_node.image_id
  flavor_name     = var.horovod_master_node.flavor_name
  key_pair        = var.horovod_master_node.key_pair
  security_groups = ["default", "${openstack_networking_secgroup_v2.terraform_horovod_master.name}", "${openstack_networking_secgroup_v2.terraform_ALL.name}"]
  
  provisioner "local-exec" {
    working_dir = "./"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_RETRIES=10 sleep 30 && ansible-playbook -i '${self.access_ip_v4},' ../horovod_master.yaml --extra-vars \"PROMETHEUS_IP=${openstack_compute_instance_v2.monitoring_server.access_ip_v4} NODE_NAME=Horovod_master SELF_NODE_IP=${self.access_ip_v4}\" "
  }
}


resource "openstack_compute_instance_v2" "horovod_workers" {
  name            = var.horovod_worker_node.name
  count           = var.horovod_worker_node.count
  flavor_name     = var.horovod_worker_node.flavor_name
  image_id        = var.horovod_worker_node.image_id
  key_pair        = var.horovod_worker_node.key_pair
  security_groups = ["default", "${openstack_networking_secgroup_v2.terraform_ALL.name}"]

   provisioner "local-exec" {
    working_dir = "./"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_RETRIES=10 sleep 30 && ansible-playbook -i '${self.access_ip_v4},' ../horovod_worker.yaml --extra-vars \"NFS_SERVER=${openstack_compute_instance_v2.horovod_master.access_ip_v4} NODE_NAME=Horovod_worker PROMETHEUS_IP=${openstack_compute_instance_v2.monitoring_server.access_ip_v4} SELF_NODE_IP=${self.access_ip_v4}\" "
  }

}


# Define variables
variable "auth_data" {
  type = object({
    user_name = string
    password = string
  })
  sensitive = true
}

variable "openstack_provider" {
  type = object({
    tenant_name = string
    auth_url = string
})
}

variable "horovod_master_node" {
  type = object({
    name = string
    flavor_name = string
    image_id = string
    key_pair = string
    floating_ip= string
})
}

variable "monitoring_server_node" {
  type = object({
    name = string
    flavor_name = string
    image_id = string
    key_pair = string
    floating_ip= string
})
}

variable "horovod_worker_node" {
  type = object({
    name = string
    count = number
    flavor_name = string
    image_id = string
    key_pair = string
})
}

variable "horovod_network" {
  type = object({
    network_subnet_range = string
})
}
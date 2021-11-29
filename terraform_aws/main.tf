terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = var.aws_provider.region
  access_key = var.auth_data.access_key
  secret_key = var.auth_data.secret_key
}

# Define network resources
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "Horovod vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr_block

  tags = {
    Name = "Horovod subnet"
  }

}

resource "aws_route_table" "horovod_route_table" {
  vpc_id = aws_vpc.main.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  tags = {
    Name = "Horovod Route Table"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Horovod Gateway"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.horovod_route_table.id
}

resource "aws_security_group" "terraform_monitoring_server" {
  name        = "terraform_monitoring_server"
  description = "security group for monitoring server"
  vpc_id      = aws_vpc.main.id

  ingress {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
  ingress {
      description      = "TLS from VPC"
      from_port        = 9090
      to_port          = 9090
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  ingress {
      description      = "TLS from VPC"
      from_port        = 8500
      to_port          = 8500
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  ingress {
      description      = "TLS from VPC"
      from_port        = 3000
      to_port          = 3000
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  

  tags = {
    Name = "secgroup_terraform_monitoring_server"
  }
}

resource "aws_security_group" "terraform_ALL" {
  name        = "terraform_ALL"
  description = "security group for terraform_ALL"
  vpc_id      = aws_vpc.main.id

  ingress {
      description      = "TLS from VPC"
      from_port        = 1
      to_port          = 65535
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
  ingress {
      description      = "TLS from VPC"
      from_port        = 1
      to_port          = 65535
      protocol         = "udp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  ingress {
      description      = "TLS from VPC"
      from_port        = -1
      to_port          = -1
      protocol         = "icmp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_security_group" "terraform_horovod_master" {
  name        = "terraform_horovod_master"
  description = "security group for terraform_horovod_master"
  vpc_id      = aws_vpc.main.id

  ingress {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
  ingress {
      description      = "TLS from VPC"
      from_port        = 8888
      to_port          = 8888
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  

  tags = {
    Name = "allow_tls"
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "monitoring_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.monitoring_server_node.instance_type
  
  subnet_id = aws_subnet.main_subnet.id
  vpc_security_group_ids = [
    aws_security_group.terraform_ALL.id,
    aws_security_group.terraform_monitoring_server.id
    ]
  associate_public_ip_address = true
  key_name = var.monitoring_server_node.key_pair

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }


  provisioner "local-exec" {
    working_dir = "./"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_RETRIES=10 sleep 60 && ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.ssh_path} monitoring_server.yaml --extra-vars \"PROMETHEUS_IP=${self.public_ip} NODE_NAME=Monitoring_server SELF_NODE_IP=${self.private_ip} \" "
  }

  tags = {
    Name = "Monitoring server"
  }
}

resource "aws_instance" "horovod_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.horovod_master_node.instance_type

  subnet_id = aws_subnet.main_subnet.id
  vpc_security_group_ids = [
    aws_security_group.terraform_ALL.id,
    aws_security_group.terraform_horovod_master.id
    ]
  associate_public_ip_address = true
  key_name = var.horovod_master_node.key_pair

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  provisioner "local-exec" {
    working_dir = "./"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_RETRIES=10 sleep 60 && ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.ssh_path} horovod_master.yaml --extra-vars \"PROMETHEUS_IP=${aws_instance.monitoring_server.private_ip} NODE_NAME=Horovod_master SELF_NODE_IP=${self.private_ip}\" "
  }

  tags = {
    Name = "Horovod Master server"
  }
}

resource "aws_instance" "horovod_workers" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.horovod_worker_node.instance_type
  count         = var.horovod_worker_node.count

  subnet_id = aws_subnet.main_subnet.id
  vpc_security_group_ids = [
    aws_security_group.terraform_ALL.id,
    ]
  associate_public_ip_address = true
  key_name = var.horovod_worker_node.key_pair

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  provisioner "local-exec" {
    working_dir = "./"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_RETRIES=10 sleep 60 && ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.ssh_path} horovod_worker.yaml --extra-vars \"NFS_SERVER=${aws_instance.horovod_master.private_ip} NODE_NAME=Horovod_worker PROMETHEUS_IP=${aws_instance.monitoring_server.private_ip} SELF_NODE_IP=${self.private_ip}\" "
  }

  tags = {
    Name = "Horovod Worker server"
  }
}


# Define variables
variable "auth_data" {
  type = object({
    access_key = string
    secret_key = string
  })
  sensitive = true
}

variable "aws_provider" {
  type = object({
    region = string
})
}

variable "horovod_master_node" {
  type = object({
    name = string
    instance_type = string
    key_pair = string
    floating_ip= string
})
}

variable "monitoring_server_node" {
  type = object({
    name = string
    instance_type = string
    key_pair = string
    floating_ip= string
})
}

variable "horovod_worker_node" {
  type = object({
    name = string
    count = number
    instance_type = string
    key_pair = string
})
}

variable "horovod_network" {
  type = object({
    network_subnet_range = string
})
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable ssh_path {}

# Set values to the variables

aws_provider = ({
    region = "eu-central-1"
})

horovod_master_node = ({
    name = "horovod_master"
    instance_type  = "t2.micro"
    key_pair = "horovod-sshkey"
    floating_ip= "SET_YOUR_FLOATING_IP"
})

horovod_worker_node = ({
    name = "horovod_worker"
    count = 1
    instance_type = "t2.micro"
    key_pair = "horovod-sshkey"
    floating_ip= "SET_YOUR_FLOATING_IP"

})

monitoring_server_node = ({
    name = "monitoring_server"
    instance_type = "t2.micro"
    key_pair = "horovod-sshkey"
    floating_ip= "SET_YOUR_FLOATING_IP"
})

horovod_network = ({
    network_subnet_range = "192.168.0.0/16"
})

vpc_cidr_block = "10.0.0.0/16"
subnet_cidr_block = "10.0.10.0/24"
ssh_path = "/home/executor/Desktop/terraform_aws/horovod-sshkey.pem"

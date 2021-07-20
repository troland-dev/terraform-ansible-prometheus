# Set values to the variables

openstack_provider = ({
    tenant_name = "DDL"
    auth_url = "https://sztaki.cloud.mta.hu:5000/v3"
})

horovod_master_node = ({
    name = "horovod_master"
    flavor_name = "m1.medium"
    image_id = "88bafb03-b169-4289-8f6f-c0cffc9177ca"
    key_pair = "my-sshkey"
    floating_ip= "SET_YOUR_FLOATING_IP"
})

horovod_worker_node = ({
    name = "horovod_worker"
    count = 1
    flavor_name = "m1.medium"
    image_id = "88bafb03-b169-4289-8f6f-c0cffc9177ca"
    key_pair = "my-sshkey"
})

monitoring_server_node = ({
    name = "monitoring_server"
    flavor_name = "m1.medium"
    image_id = "88bafb03-b169-4289-8f6f-c0cffc9177ca"
    key_pair = "my-sshkey"
    floating_ip= "SET_YOUR_FLOATING_IP"
})

horovod_network = ({
    network_subnet_range = "192.168.0.0/16"
})
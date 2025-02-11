### VPC/Subnet ###
vpc_name        = "sypchik-proj"
subnet_name_pub    = "access"
subnet_name_priv    = "cluster"

zones = [ "ru-central1-a", "ru-central1-b", "ru-central1-d" ]
public_cidr = [ "192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24" ]
private_cidr = [ "10.10.10.0/24", "10.10.20.0/24", "10.10.30.0/24" ]

### Security group / Goute table ###
sg_nat_name          = "nat-instance-sg"
route_table_name     = "nat-instance-route"

### Cloud Init ###
pack_list           = ["libsoup-2.4-1","libsoup2.4-common","libsoup2.4-dev","libappstream5","python3","python3-pip","curl","net-tools","ca-certificates","apt-transport-https","ssh"]
sudo_cloud_init     = "ALL=(ALL) NOPASSWD:ALL"
sudo_vm_u_group     = "sudo"
vm_u_shell          = "/bin/bash"

### VM Platform ###
image_family    = "ubuntu-24-04-lts"

### LoadBalancer/ LoadBalancer Group ###
group_lb_name = "ha-proxy"
lb_name = "external-kubernetes-lb"
lb_type = "external"
lb_del_prot = false
lb_list_name = "kuber-listener"
lb_list_port = 6443
lb_list_tport = 6443
lb_list_protocol = "tcp"
lb_health_name = "ha-proxy"
lb_health_interval = 2
lb_health_tout = 1
lb_health_unhthr = 2
lb_health_healthr = 2
lb_health_port = 6443


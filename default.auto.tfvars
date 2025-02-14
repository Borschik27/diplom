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
#pack_list           = ["libsoup-2.4-1","libsoup2.4-common","libsoup2.4-dev","libappstream5","python3","python3-pip","curl","net-tools","ca-certificates","apt-transport-https","ssh"]
pack_list           = ["ssh"]

sudo_cloud_init     = "ALL=(ALL) NOPASSWD:ALL"
sudo_vm_u_group     = "sudo"
vm_u_shell          = "/bin/bash"

### VM Platform ###
image_family    = "ubuntu-24-04-lts"

### LoadBalancer/ LoadBalancer Group ###
group_lb_name_kuber = "ha-proxy"
lb_name_kuber = "external-kubernetes-lb"
lb_type_kuber = "external"
lb_del_prot_kuber = false
lb_list_name_kuber = "kuber-listener"
lb_list_port_kuber = 6443
lb_list_tport_kuber = 6443
lb_list_protocol_kuber = "tcp"
lb_health_name_kuber = "ha-proxy"
lb_health_interval_kuber = 2
lb_health_tout_kuber = 1
lb_health_unhthr_kuber = 2
lb_health_healthr_kuber = 2
lb_health_port_kuber = 6443

group_lb_name_ingress = "kuber-ingress"
lb_name_ingress = "external-ingress-lb"
lb_type_ingress = "external"
lb_del_prot_ingress = false
lb_list_name_ingress = "ingress-listener"
lb_list_port_ingress = 80
lb_list_tport_ingress = 32080
lb_list_protocol_ingress = "tcp"
lb_health_name_ingress = "kuber-ingress"
lb_health_interval_ingress = 2
lb_health_tout_ingress = 1
lb_health_unhthr_ingress = 2
lb_health_healthr_ingress = 2
lb_health_port_ingress = 32080


###### Create VPC and Subnet ######
resource "yandex_vpc_network" "sypchik" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "public" {
  count = length(var.zones)

  name           = "${var.subnet_name_pub}-${var.zones[count.index]}"
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.sypchik.id
  v4_cidr_blocks = [var.public_cidr[count.index]]
}

resource "yandex_vpc_subnet" "cluster" {
  count = length(var.zones)

  name           = "${var.subnet_name_priv}-${var.zones[count.index]}"
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.sypchik.id
  v4_cidr_blocks = [var.private_cidr[count.index]]
  route_table_id = yandex_vpc_route_table.nat_instance_route[var.zones[count.index]].id
}

###### Init Static Public address ######
### Nat Static IPs ###
resource "yandex_vpc_address" "nat_addr" {
  count = length(var.zones)

  name                = "nat-ip-${var.zones[count.index]}"
  deletion_protection = false
  external_ipv4_address {
    zone_id = var.zones[count.index]
  }
}

### LoadBalancer Static IP ###
resource "yandex_vpc_address" "lb-addr" {
  count = 2

  name                = "lb-ip${count.index}"
  deletion_protection = false
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

###### Set Images ######
data "yandex_compute_image" "my_image" {
  family = var.image_family
}

###### Render Cloud Inits ######
### Nat Instance ###
data "template_file" "cloudinit_services" {
  template = file("${path.module}/templates/cloud-init-services.yaml.tpl")

  vars = {
    ssh_key          = var.vms_ssh_root_key,
    uname            = var.vm_user,
    ugroup           = var.sudo_vm_u_group,
    shell            = var.vm_u_shell,
    s_com            = var.sudo_cloud_init,
    pack             = join("\n  - ", var.pack_list),
    vm_user_password = var.vm_user_password
  }
}

### Jump Server ###
data "template_file" "cloudinit_jump" {
  template = file("${path.module}/templates/cloud-init-jump.yaml.tpl")

  vars = {
    ssh_key          = var.vms_ssh_root_key,
    uname            = var.vm_user,
    ugroup           = var.sudo_vm_u_group,
    shell            = var.vm_u_shell,
    s_com            = var.sudo_cloud_init,
    pack             = join("\n  - ", var.pack_list),
    vm_user_password = var.vm_user_password
  }
}

### Ubuntu 24.04 ###
data "template_file" "cloudinit_2404" {
  template = file("${path.module}/templates/cloud-init-2404.yaml.tpl")

  vars = {
    ssh_key          = var.vms_ssh_root_key,
    uname            = var.vm_user,
    ugroup           = var.sudo_vm_u_group,
    shell            = var.vm_u_shell,
    s_com            = var.sudo_cloud_init,
    pack             = join("\n  - ", var.pack_list),
    vm_user_password = var.vm_user_password
  }
}

###### Create NAT Instances ######
resource "yandex_compute_instance" "nat" {
  for_each = var.vms_resources_nat

  name        = "${each.value.name}-${each.value.zone}"
  platform_id = each.value.platform_id
  zone        = each.value.zone
  hostname    = each.value.hostname

  metadata = {
    user-data          = data.template_file.cloudinit_services.rendered
    serial-port-enable = 1
  }

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = each.value.services_image_id
      size     = each.value.hdd_size
      type     = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public[index(var.zones, each.value.zone)].id
    nat                = each.value.nat_status
    ip_address         = each.value.local_ip
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
    nat_ip_address     = yandex_vpc_address.nat_addr[index(var.zones, each.value.zone)].external_ipv4_address[0].address
  }
}

###### Create Route Table ######
resource "yandex_vpc_route_table" "nat_instance_route" {
  for_each = var.vms_resources_nat

  name       = "${var.route_table_name}-${each.value.zone}"
  network_id = yandex_vpc_network.sypchik.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat[each.key].network_interface[0].ip_address
  }
}

###### Create security group ######
resource "yandex_vpc_security_group" "nat_instance_sg" {
  name       = var.sg_nat_name
  network_id = yandex_vpc_network.sypchik.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Load Balancer (e.g. HAProxy)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # Разрешаем трафик для взаимодействия с etcd

  ingress {
    protocol       = "TCP"
    description    = "etcd communication"
    v4_cidr_blocks = ["10.10.10.0/24", "10.10.20.0/24", "10.10.30.0/24"] # IP диапазоны для узлов кластера
    port           = 2379
  }

  ingress {
    protocol       = "TCP"
    description    = "etcd communication"
    v4_cidr_blocks = ["10.10.10.0/24", "10.10.20.0/24", "10.10.30.0/24"]
    port           = 2380
  }

  # Разрешаем трафик с API-сервера к etcd
  ingress {
    protocol       = "TCP"
    description    = "API server to etcd"
    v4_cidr_blocks = ["10.96.0.0/12"] # IP-диапазон для API-сервера Kubernetes
    port           = 2379
  }

  # --- Calico ---
  # BGP (Border Gateway Protocol)
  ingress {
    protocol       = "TCP"
    description    = "Calico BGP"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 179
  }

  ingress {
    protocol       = "UDP"
    description    = "Calico BGP"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 179
  }

  ingress {
    protocol       = "TCP"
    description    = "Calico health check"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 9099
  }

  # --- MetalLB ---
  ingress {
    protocol       = "TCP"
    description    = "MetalLB Webhook"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "MetalLB Controller"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 7472
  }

  ingress {
    protocol       = "TCP"
    description    = "MetalLB L2 communication"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 7946
  }

  ingress {
    protocol       = "UDP"
    description    = "MetalLB L2 communication"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 7946
  }

  ingress {
    protocol       = "TCP"
    description    = "MetalLB BGP"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 179
  }
}

###### Create HA Proxy Instances ######
resource "yandex_compute_instance" "ha" {
  for_each = var.vms_resources_ha

  name        = "${each.value.name}-${each.value.zone}"
  platform_id = each.value.platform_id
  zone        = each.value.zone
  hostname    = each.value.hostname

  metadata = {
    user-data          = data.template_file.cloudinit_2404.rendered
    serial-port-enable = 1
  }

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size     = each.value.hdd_size
      type     = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.cluster[index(var.zones, each.value.zone)].id
    nat                = each.value.nat_status
    ip_address         = each.value.local_ip
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }
}


###### Create LoadBalancer group ######
###  HAProxy ###
resource "yandex_lb_target_group" "ha-proxy" {
  name      = var.group_lb_name_kuber
  folder_id = var.folder_id

  dynamic "target" {
    for_each = yandex_compute_instance.ha

    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

### Nginx-Ingress ###
resource "yandex_lb_target_group" "nginx-ingress" {
  name      = var.group_lb_name_ingress
  folder_id = var.folder_id

  dynamic "target" {
    for_each = {
      for k, v in yandex_compute_instance.kubernetes_workers : k => v
      if substr(k, 0, 4) == "w01-"
    }

    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

###### Create External LoadBalancer ######
### LoadBalancer for ControlEndpointPalne ###
resource "yandex_lb_network_load_balancer" "external-lb-kuber" {
  name                = var.lb_name_kuber
  type                = var.lb_type_kuber
  deletion_protection = var.lb_del_prot_kuber
  folder_id           = var.folder_id

  listener {
    name        = var.lb_list_name_kuber
    port        = var.lb_list_port_kuber
    target_port = var.lb_list_tport_kuber
    protocol    = var.lb_list_protocol_kuber
    external_address_spec {
      address = yandex_vpc_address.lb-addr[0].external_ipv4_address[0].address
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.ha-proxy.id

    healthcheck {
      name                = var.lb_health_name_kuber
      interval            = var.lb_health_interval_kuber
      timeout             = var.lb_health_tout_kuber
      unhealthy_threshold = var.lb_health_unhthr_kuber
      healthy_threshold   = var.lb_health_healthr_kuber
      tcp_options {
        port = var.lb_health_port_kuber
      }
    }
  }
}

### LoadBalancer for Kubernetes nginx-ingress ###
resource "yandex_lb_network_load_balancer" "external-lb-ingress" {
  name                = var.lb_name_ingress
  type                = var.lb_type_ingress
  deletion_protection = var.lb_del_prot_ingress
  folder_id           = var.folder_id

  listener {
    name        = var.lb_list_name_ingress
    port        = var.lb_list_port_ingress
    target_port = var.lb_list_tport_ingress
    protocol    = var.lb_list_protocol_ingress
    external_address_spec {
      address = yandex_vpc_address.lb-addr[1].external_ipv4_address[0].address
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.nginx-ingress.id

    healthcheck {
      name                = var.lb_health_name_ingress
      interval            = var.lb_health_interval_ingress
      timeout             = var.lb_health_tout_ingress
      unhealthy_threshold = var.lb_health_unhthr_ingress
      healthy_threshold   = var.lb_health_healthr_ingress
      tcp_options {
        port = var.lb_health_port_ingress
      }
    }
  }
}



###### Kubernetes Master Instances ######
resource "yandex_compute_instance" "kubernetes" {
  for_each = var.vms_resources_kuber_master

  name        = "${each.value.name}-${each.value.zone}"
  platform_id = each.value.platform_id
  zone        = each.value.zone
  hostname    = each.value.hostname

  metadata = {
    user-data          = data.template_file.cloudinit_2404.rendered
    serial-port-enable = 1
  }

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size     = each.value.hdd_size
      type     = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.cluster[index(var.zones, each.value.zone)].id
    nat                = each.value.nat_status
    ip_address         = each.value.local_ip
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }
}

###### Kubernetes Workers Instances ######
resource "yandex_compute_instance" "kubernetes_workers" {
  for_each = var.vms_resources_kuber_worker

  name        = "${each.value.name}-${each.value.zone}"
  platform_id = each.value.platform_id
  zone        = each.value.zone
  hostname    = each.value.hostname

  metadata = {
    user-data          = data.template_file.cloudinit_2404.rendered
    serial-port-enable = 1
  }

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size     = each.value.hdd_size
      type     = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.cluster[index(var.zones, each.value.zone)].id
    nat                = each.value.nat_status
    ip_address         = each.value.local_ip
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }
}

###### SSH Jump Server ######
resource "yandex_compute_instance" "jump_server" {
  name        = "jump-server"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  hostname    = "jump"

  metadata = {
    user-data          = data.template_file.cloudinit_jump.rendered
    serial-port-enable = 1
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public[0].id
    nat                = "true"
    ip_address         = "192.168.10.8"
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }
}



###### Create Ansible files ######
### Inventory hosts.yaml ###
resource "local_file" "ansible_inventory" {
  depends_on = [yandex_compute_instance.kubernetes, yandex_compute_instance.kubernetes_workers, yandex_compute_instance.ha]

  filename = "${path.module}/ansible/inventory/hosts.yaml"
  content = templatefile("${path.module}/templates/hosts.yaml.tpl", {
    vm_details = merge(
      { for vm in yandex_compute_instance.kubernetes : vm.name => {
        ip       = vm.network_interface[0].nat_ip_address
        local_ip = vm.network_interface[0].ip_address
        }
      },
      { for vm in yandex_compute_instance.kubernetes_workers : vm.name => {
        ip       = vm.network_interface[0].nat_ip_address
        local_ip = vm.network_interface[0].ip_address
        }
      },
      { for vm in yandex_compute_instance.ha : vm.name => {
        ip       = vm.network_interface[0].nat_ip_address
        local_ip = vm.network_interface[0].ip_address
        }
      },
      { for vm in yandex_compute_instance.nat : vm.name => {
        ip       = vm.network_interface[0].nat_ip_address
        local_ip = vm.network_interface[0].ip_address
        }
      }
    )
    vm_user = var.vm_user
  })
}

### Render ansible.cfg ###
resource "local_file" "ansible_cfg" {
  depends_on = [yandex_compute_instance.kubernetes, yandex_compute_instance.kubernetes_workers, yandex_compute_instance.ha]

  filename = "${path.module}/ansible/ansible.cfg"
  content = templatefile("${path.module}/templates/ansible.cfg.tpl", {
    ip   = yandex_compute_instance.jump_server.network_interface[0].nat_ip_address
    user = var.vm_user
  })
}

### Render haproxy.cfg ###
resource "local_file" "haproxy_conf" {
  depends_on = [yandex_compute_instance.kubernetes, yandex_compute_instance.kubernetes_workers, yandex_compute_instance.ha]

  filename = "${path.module}/ansible/roles/keep-ha/files/haproxy.cfg"
  content = templatefile("${path.module}/templates/haproxy.cfg.tpl", {
    vm_details = { for instance in yandex_compute_instance.kubernetes :
      instance.name => {
        hostname = instance.hostname
        local_ip = instance.network_interface[0].ip_address
      }
    }
  })
}

### Render example init conif file for kuber ###
resource "local_file" "kuber_init_conf" {
  depends_on = [yandex_compute_instance.kubernetes, yandex_compute_instance.kubernetes_workers, yandex_compute_instance.ha]

  filename = "${path.module}/ansible/roles/kuber/files/init-config-example.yaml"
  content = templatefile("${path.module}/templates/init-config-example.yaml.tpl", {
    ip = yandex_vpc_address.lb-addr[0].external_ipv4_address[0].address
  })
}

### Start ansible playbook ###
resource "null_resource" "ansible_apply" {
  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_CONFIG=ansible/ansible.cfg  ansible-playbook -i ${path.module}/ansible/inventory/hosts.yaml ${path.module}/ansible/playbooks/site.yaml
    EOT

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "false"
    }
  }

  depends_on = [local_file.ansible_inventory, local_file.ansible_cfg, null_resource.wait_for_cloud_init]
}

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

  name = "nat-ip-${var.zones[count.index]}"
  deletion_protection = false
  external_ipv4_address {
    zone_id = var.zones[count.index]
  }
}

### LoadBalancer Static IP ###
resource "yandex_vpc_address" "lb-addr" {
  name = "lb-ip"
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
            size = each.value.hdd_size
            type = each.value.hdd_type
        }
    }

    network_interface {
        subnet_id   = yandex_vpc_subnet.public[index(var.zones, each.value.zone)].id
        nat         = each.value.nat_status
        ip_address  = each.value.local_ip
        security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
        nat_ip_address = yandex_vpc_address.nat_addr[index(var.zones, each.value.zone)].external_ipv4_address[0].address
    }
}

###### Create Route Table ######
resource "yandex_vpc_route_table" "nat_instance_route" {
  for_each  = var.vms_resources_nat

  name       = "${var.route_table_name}-${each.value.zone}"
  network_id = yandex_vpc_network.sypchik.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address = yandex_compute_instance.nat[each.key].network_interface[0].ip_address
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
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
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
}

###### Create HA Proxy Instances ######
resource "yandex_compute_instance" "ha" {
    for_each = var.vms_resources_ha

    name        = "${each.value.name}-${each.value.zone}"
    platform_id = each.value.platform_id
    zone        = each.value.zone
    hostname    = each.value.hostname

    # metadata = {
    #     user-data          = data.template_file.cloudinit_services.rendered
    #     serial-port-enable = 1
    # }

    resources {
        cores         = each.value.cores
        memory        = each.value.memory
        core_fraction = each.value.core_fraction
    }

    boot_disk {
        initialize_params {
            image_id = data.yandex_compute_image.my_image.id
            size = each.value.hdd_size
            type = each.value.hdd_type
        }
    }

    network_interface {
        subnet_id   = yandex_vpc_subnet.cluster[index(var.zones, each.value.zone)].id
        nat         = each.value.nat_status
        ip_address  = each.value.local_ip
        security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
    }
}


###### Create HA Proxy loadbalancer group ######
resource "yandex_lb_target_group" "ha-proxy" {
    name      = var.group_lb_name
    folder_id = var.folder_id

    dynamic "target" {
      for_each = yandex_compute_instance.ha

      content {
        subnet_id = target.value.network_interface[0].subnet_id
        address = target.value.network_interface[0].ip_address
      } 
    }
}


###### Create External LoadBalancer ######
resource "yandex_lb_network_load_balancer" "external-lb-kuber" {
  name               = var.lb_name
  type               = var.lb_type
  deletion_protection = var.lb_del_prot
  folder_id          = var.folder_id

  listener {
    name        = var.lb_list_name
    port        = var.lb_list_port
    target_port = var.lb_list_tport
    protocol    = var.lb_list_protocol
    external_address_spec {
      address = yandex_vpc_address.lb-addr.external_ipv4_address[0].address
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.ha-proxy.id

    healthcheck {
      name                = var.lb_health_name
      interval            = var.lb_health_interval
      timeout             = var.lb_health_tout
      unhealthy_threshold = var.lb_health_unhthr
      healthy_threshold   = var.lb_health_healthr
      tcp_options {
        port = var.lb_health_port
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

  # metadata = {
  #   user-data          = data.template_file.cloudinit_services.rendered
  #   serial-port-enable = 1
  # }

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size = each.value.hdd_size
      type = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id   = yandex_vpc_subnet.cluster[index(var.zones, each.value.zone)].id
    nat         = each.value.nat_status
    ip_address  = each.value.local_ip
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

  # metadata = {
  #   user-data          = data.template_file.cloudinit_services.rendered
  #   serial-port-enable = 1
  # }

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size = each.value.hdd_size
      type = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id   = yandex_vpc_subnet.cluster[index(var.zones, each.value.zone)].id
    nat         = each.value.nat_status
    ip_address  = each.value.local_ip
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }
}

###### Create Ansible Inventory yaml file ######
resource "local_file" "ansible_inventory" {
  depends_on = [yandex_compute_instance.kubernetes, yandex_compute_instance.kubernetes_workers, yandex_compute_instance.ha]

  filename = "${path.module}/ansible/inventory/hosts.yaml"
  content  = templatefile("${path.module}/templates/hosts.yaml.tpl", {
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
    vm_user    = var.vm_user
  })
}
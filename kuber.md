При использовании Внешнего балансировшика нагрузки вместе с haproxy как в данном примере нужно открывать порты в Группе безопастности для всего!!!!
Искать какие порты под какие сервисы, важно смотреть как конфигурируется сервер и что используется

Пример: 

CALICO:
`resource "yandex_vpc_security_group" "nat_instance_sg" {
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

  #  Разрешаем трафик для взаимодействия с LoadBalancer
  ingress {
    protocol       = "TCP"
    description    = "Load Balancer (e.g. HAProxy)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # Разрешаем трафик для взаимодействия с etcd
  ingress {
    protocol       = "TCP"
    description    = "etcd communication"
    v4_cidr_blocks = ["10.10.10.0/24", "10.10.20.0/24", "10.10.30.0/24"]
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
    v4_cidr_blocks = ["10.96.0.0/12"]
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

  # VXLAN (или IP-in-IP)
  ingress {
    protocol       = "UDP"
    description    = "Calico VXLAN"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 4789
  }

  ingress {
    protocol       = "UDP"
    description    = "Calico IP-in-IP"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 6081
  }

  # Typha (оптимизация работы calico)
  ingress {
    protocol       = "TCP"
    description    = "Calico Typha"
    v4_cidr_blocks = ["10.10.0.0/16"]
    port           = 5473
  }

  # Liveness/Readiness Probes
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
`
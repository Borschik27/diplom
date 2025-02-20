vms_resources_nat = {
  "ru-central1-a" = {
    name              = "nat-instance"
    platform_id       = "standard-v3"
    cores             = 2
    memory            = 2
    hdd_size          = 30
    hdd_type          = "network-hdd"
    core_fraction     = 50
    hostname          = "nat-instance-a"
    nat_status        = true
    zone              = "ru-central1-a"
    local_ip          = "192.168.10.254"
    cidr_block        = "192.168.10.0/24"
    services_image_id = "fd8lq67qr9o6fhjc64fl"
  }

  "ru-central1-b" = {
    name              = "nat-instance"
    platform_id       = "standard-v3"
    cores             = 2
    memory            = 2
    hdd_size          = 30
    hdd_type          = "network-hdd"
    core_fraction     = 50
    hostname          = "nat-instance-b"
    nat_status        = true
    zone              = "ru-central1-b"
    local_ip          = "192.168.20.254"
    cidr_block        = "192.168.20.0/24"
    services_image_id = "fd8lq67qr9o6fhjc64fl"
  }

  "ru-central1-d" = {
    name              = "nat-instance"
    platform_id       = "standard-v3"
    cores             = 2
    memory            = 2
    hdd_size          = 30
    hdd_type          = "network-hdd"
    core_fraction     = 50
    hostname          = "nat-instance-d"
    nat_status        = true
    zone              = "ru-central1-d"
    local_ip          = "192.168.30.254"
    cidr_block        = "192.168.30.0/24"
    services_image_id = "fd8lq67qr9o6fhjc64fl"
  }
}

vms_resources_ha = {
  "ru-central1-a" = {
    name          = "ha"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 30
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "ha-a"
    nat_status    = false
    zone          = "ru-central1-a"
    local_ip      = "10.10.10.10"
    cidr_block    = "10.10.10.0/24"
  }

  "ru-central1-b" = {
    name          = "ha"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 30
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "ha-b"
    nat_status    = false
    zone          = "ru-central1-b"
    local_ip      = "10.10.20.10"
    cidr_block    = "10.10.20.0/24"
  }

  "ru-central1-d" = {
    name          = "ha"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 30
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "ha-d"
    nat_status    = false
    zone          = "ru-central1-d"
    local_ip      = "10.10.30.10"
    cidr_block    = "10.10.30.0/24"
  }
}

vms_resources_kuber_master = {
  "master-01" = {
    name          = "master"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 4
    hdd_size      = 60
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "master-a"
    nat_status    = false
    zone          = "ru-central1-a"
    local_ip      = "10.10.10.5"
    cidr_block    = "10.10.10.0/24"
  }

  "master-02" = {
    name          = "master"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 4
    hdd_size      = 60
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "master-b"
    nat_status    = false
    zone          = "ru-central1-b"
    local_ip      = "10.10.20.5"
    cidr_block    = "10.10.20.0/24"
  }

  "master-03" = {
    name          = "master"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 4
    hdd_size      = 60
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "master-d"
    nat_status    = false
    zone          = "ru-central1-d"
    local_ip      = "10.10.30.5"
    cidr_block    = "10.10.30.0/24"
  }
}

vms_resources_kuber_worker = {
  "w01-a" = {
    name          = "kw01"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 20
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "kw01-a"
    nat_status    = false
    zone          = "ru-central1-a"
    local_ip      = "10.10.10.101"
    cidr_block    = "10.10.10.0/24"
  }

  "w02-a" = {
    name          = "kw02"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 20
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "kw02-a"
    nat_status    = false
    zone          = "ru-central1-a"
    local_ip      = "10.10.10.102"
    cidr_block    = "10.10.20.0/24"
  }

  "w01-b" = {
    name          = "kw01"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 20
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "kw01-b"
    nat_status    = false
    zone          = "ru-central1-b"
    local_ip      = "10.10.20.101"
    cidr_block    = "10.10.20.0/24"
  }

  "w02-b" = {
    name          = "kw02"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 20
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "kw02-b"
    nat_status    = false
    zone          = "ru-central1-b"
    local_ip      = "10.10.20.102"
    cidr_block    = "10.10.20.0/24"
  }

  "w01-d" = {
    name          = "kw01"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 4
    hdd_size      = 60
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "kw01-d"
    nat_status    = false
    zone          = "ru-central1-d"
    local_ip      = "10.10.30.101"
    cidr_block    = "10.10.30.0/24"
  }

  "w02-d" = {
    name          = "kw02"
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 2
    hdd_size      = 20
    hdd_type      = "network-hdd"
    core_fraction = 50
    hostname      = "kw02-d"
    nat_status    = false
    zone          = "ru-central1-d"
    local_ip      = "10.10.30.102"
    cidr_block    = "10.10.30.0/24"
  }
}
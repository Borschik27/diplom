output "vm_details" {
  description = "Important values"

  value = {
    nat_instances = {
      for instance in yandex_compute_instance.nat :
      instance.name => {
        hostname  = instance.hostname
        zone      = instance.zone
        ip        = try(instance.network_interface[0].nat_ip_address, "N/A")
        local_ip  = instance.network_interface[0].ip_address
      }
    }
    ha_instances = {
      for instance in yandex_compute_instance.ha :
      instance.name => {
        hostname  = instance.hostname
        ip        = try(instance.network_interface[0].nat_ip_address, "N/A")
        local_ip  = instance.network_interface[0].ip_address
        zone      = instance.zone
      }
    }
    kubernetes_masters = {
      for instance in yandex_compute_instance.kubernetes :
      instance.name => {
        hostname  = instance.hostname
        ip        = try(instance.network_interface[0].nat_ip_address, "N/A")
        local_ip  = instance.network_interface[0].ip_address
        zone      = instance.zone
      }
    }
    kubernetes_workers = {
      for instance in yandex_compute_instance.kubernetes_workers :
      instance.name => {
        hostname  = instance.hostname
        ip        = try(instance.network_interface[0].nat_ip_address, "N/A")
        local_ip  = instance.network_interface[0].ip_address
        zone      = instance.zone
      }
    }
  }
}

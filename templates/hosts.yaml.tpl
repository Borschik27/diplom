all:
  hosts:
    localhost:
      ansible_connection: local
%{ for vm_name, vm_data in vm_details ~}
    ${vm_name}:
      ansible_host: ${vm_data.ip}
      ansible_user: ${vm_user}
      ansible_port: 22
      ansible_connection: ssh
      local_ip: ${vm_data.local_ip}
%{ endfor ~}

  children:
    nat:
      hosts:
%{ for vm_name, vm_data in vm_details ~}
%{ if startswith(vm_name, "nat") ~}
        ${vm_name}:
%{ endif ~}
%{ endfor ~}

    ha-proxy:
      hosts:
%{ for vm_name, vm_data in vm_details ~}
%{ if startswith(vm_name, "ha") ~}
        ${vm_name}:
%{ endif ~}
%{ endfor ~}

    kuber:
      children:
        master:
          hosts:
%{ for vm_name, vm_data in vm_details ~}
%{ if startswith(vm_name, "master") ~}
            ${vm_name}:
%{ endif ~}
%{ endfor ~}

        worker:
          hosts:
%{ for vm_name, vm_data in vm_details ~}
%{ if startswith(vm_name, "kw") ~}
            ${vm_name}:
%{ endif ~}
%{ endfor ~}


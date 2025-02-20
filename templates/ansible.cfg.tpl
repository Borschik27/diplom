[defaults]
inventory = ./inventory/hosts.yaml
roles_path = ./roles
log_path = ./ansible_log
host_key_checking = False
remote_tmp = /tmp/.ansible-${user}

[ssh_connection]
ansible_connection = ssh
ssh_common_args= "-o ProxyJump=${user}@${ip} -o StrictHostKeyChecking=no"
ansible_python_interpreter = /usr/bin/python3
private_key_file = ~/.ssh/id_rsa
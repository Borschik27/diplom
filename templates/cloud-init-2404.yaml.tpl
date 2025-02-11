#cloud-config
users:
  - name: ${uname}
    groups: ${ugroup}
    shell: ${shell}
    sudo: ["${s_com}"]
    plain_text_passwd: ${vm_user_password}
    lock_passwd: false
    ssh_authorized_keys:
      - ${ssh_key}

write_files:
  - path: /etc/ssh/sshd_config.d/99-cloud-init.conf
    content: |
      PasswordAuthentication yes
      PermitRootLogin yes
      ChallengeResponseAuthentication no

runcmd:
  - systemctl restart ssh

packages:
  - ${pack}
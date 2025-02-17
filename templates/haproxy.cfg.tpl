global
  log /dev/log    local0 warning
  log /dev/log    local1 notice
  chroot          /var/lib/haproxy
  stats socket    /run/haproxy/admin.sock mode 660 level admin
  pidfile         /var/run/haproxy.pid
  maxconn         4000
  user            haproxy
  group           haproxy
  daemon

defaults
  log     global
  option  httplog
  option  dontlognull
  timeout connect 5000
  timeout client 50000
  timeout server 50000

frontend kube-apiserver
  bind    *:6443
  mode    tcp
  option  tcplog
  default_backend kube-apiserver

backend kube-apiserver
  mode tcp
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
%{ for name, instance in vm_details }
  server ${name} ${instance.local_ip}:6443 check
%{ endfor }
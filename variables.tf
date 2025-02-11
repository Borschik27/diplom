###### Personal variables ######
variable "cloud_id" {
  type        = string
}

variable "folder_id" {
  type        = string
}

variable "services_acc_id" {
  type        = string
}

variable "vms_ssh_root_key" {
  type        = string 
}

variable "vms_ssh_root_key_file" {
  type        = string 
}

variable "ppkyc" {
  type        = string
  description = "Path to key"
}

variable "vm_user" {
  description = "Username for the VM user"
  type        = string
}

variable "vm_user_password" {
  description = "Password for the VM user"
  type        = string
}


###### Default variables ######
### VPC/Subnet ###
variable "vpc_name" {
  description = "Virtual network name"
  type        = string
}

variable "subnet_name_pub" {
  description = "Subnet name public"
  type        = string
}

variable "subnet_name_priv" {
  description = "Subnet name private"
  type        = string
}

variable "zones" {
  type        = list(string)
  description = "List used zones"
}

variable "public_cidr" {
  description = "CIDR public"
  type        = list(string)
}

variable "private_cidr" {
  description = "CIDR private"
  type        = list(string)
}

### VM Platform ###
variable "image_family" {
  type        = string
  description = "ISO-img family"
}

### Cloud Init ###
variable "sudo_vm_u_group" {
  description = "User group for the VM user"
  type        = string
}

variable "vm_u_shell" {
  description = "Shell for the VM user"
  type        = string
}

variable "sudo_cloud_init" {
  description = "Sudo permissions for the user"
  type        = string
}

variable "pack_list" {
  description = "List of packages to install via Cloud-init"
  type        = list(string)
  default     = []
}


### SG / Route ###
variable "sg_nat_name" {
  description = "Security group name"
  type        = string
}

variable "route_table_name" {
  description = "Route table name"
  type        = string
}

### LoadBalancer/ LoadBalancer Group ###
variable "group_lb_name" {
  description = "Group name LB"
  type        = string
}

variable "lb_name" {
  description = "LB Name"
  type        = string
}

variable "lb_type" {
  description = "LB Type (internal/external)"
  type        = string
}

variable "lb_del_prot" {
  description = "Deleting protection"
  type        = bool
}

variable "lb_list_name" {
  description = "LB listener name"
  type        = string
}

variable "lb_list_port" {
  description = "lb listener port"
  type        = number
}

variable "lb_list_tport" {
  description = "LB listener target pot"
  type        = number
}

variable "lb_list_protocol" {
  description = "LB listener protocol"
  type        = string
}

variable "lb_health_name" {
  description = "Health name LB"
  type        = string
}

variable "lb_health_interval" {
  description = "Heath intarval (sec)"
  type        = number
}

variable "lb_health_tout" {
  description = "Health timeout (sec)"
  type        = number
}

variable "lb_health_unhthr" {
  description = "Threshold for number of failed checks"
  type        = number
}

variable "lb_health_healthr" {
  description = "Threshold for number of successful checks"
  type        = number
}

variable "lb_health_port" {
  description = "Health port"
  type        = number
}

###### For masive install mv terraform.tfvars ######
variable "vms_resources_nat" {
  type = map(object({
    name              = string
    cores             = number
    memory            = number
    hdd_size          = number
    hdd_type          = string
    core_fraction     = number
    platform_id       = string
    hostname          = string
    nat_status        = bool
    zone              = string
    local_ip          = string
    cidr_block        = string
    services_image_id = string
  }))
}

variable "vms_resources_ha" {
  type = map(object({
    name              = string
    cores             = number
    memory            = number
    hdd_size          = number
    hdd_type          = string
    core_fraction     = number
    platform_id       = string
    hostname          = string
    nat_status        = bool
    zone              = string
    local_ip          = string
    cidr_block        = string
  }))
}

variable "vms_resources_kuber_master" {
  type = map(object({
    name              = string
    cores             = number
    memory            = number
    hdd_size          = number
    hdd_type          = string
    core_fraction     = number
    platform_id       = string
    hostname          = string
    nat_status        = bool
    zone              = string
    local_ip          = string
    cidr_block        = string
  }))
}

variable "vms_resources_kuber_worker" {
  type = map(object({
    name              = string
    cores             = number
    memory            = number
    hdd_size          = number
    hdd_type          = string
    core_fraction     = number
    platform_id       = string
    hostname          = string
    nat_status        = bool
    zone              = string
    local_ip          = string
    cidr_block        = string
  }))
}
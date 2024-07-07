variable "project" {
  type = string
}
variable "vpc_id" {
  type = string

}

variable "subnet_ids" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)

}

variable "backend_port" {
  type = number

}
variable "alb_name_prefix" {
  type = string

}
variable "target_groups_name_prefix" {
  type = string

}
variable "ecs_cluster_name" {
  type = string

}
variable "efs_id" {
  type = string
  
}
variable "efs_dns_name" {
  type = string
  
}
variable "efs_mount_point" {
  type = string
  
}
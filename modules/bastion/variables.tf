variable "project" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "vpc_security_group_ids" {
  type = list(string)
  
}
variable "subnet_id" {
  type = string
  
}

variable "private_security_group_id" {
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
variable "instance_user" {
  type = string
}

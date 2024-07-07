variable "project" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}
variable "private_subnet_names" {
  type = list(string)
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "public_subnet_names" {
  type = list(string)
}
variable "database_subnets" {
  type    = list(string)
  default = ["10.0.5.0/24", "10.0.6.0/24"]
}
variable "rds_subnet_names" {
  type = list(string)
}
variable "availability_zones" {
  type = list(string)
}

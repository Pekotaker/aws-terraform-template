
variable "identifier" {
  description = "The identifier for the DB instance"
  type        = string

}
variable "allocated_storage" {
  type = number
}
variable "instance_class" {
  type = string
}
variable "db_name" {
  type = string
}
variable "username" {
  type = string
}
variable "password" {
  type = string

}
variable "availability_zone" {
  type = string

}
variable "db_subnet_group_name" {
  type = string

}
variable "vpc_security_group_ids" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}

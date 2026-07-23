variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "vpc_id" {
  description = "VPC in which the EFS security group is created."
  type        = string
}
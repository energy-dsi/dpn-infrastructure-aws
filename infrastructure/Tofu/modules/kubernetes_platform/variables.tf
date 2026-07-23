variable "application_namespace" {
  type    = string
  default = "applications"
}

variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_controller_role_arn" {
  type = string
}

variable "alb_controller_chart_version" {
  type    = string
  default = "1.14.0"
}

variable "alb_controller_image_tag" {
  type    = string
  default = "v2.14.0"
}

variable "tags" {
  type    = map(string)
  default = {}
}
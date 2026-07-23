variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "namespace" {
  type    = string
  default = "applications"
}

variable "service_account_name" {
  type    = string
  default = "federator-server"
}

variable "application_bucket_arn" {
  type = string
}

variable "secret_arns" {
  type    = list(string)
  default = ["*"]
}

variable "tags" {
  type = map(string)
}

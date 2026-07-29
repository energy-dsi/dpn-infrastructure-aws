variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "malware_protection_bucket_name" {
  type    = string
  default = null
}

variable "enable_s3_malware_protection" {
  type    = bool
  default = false
}
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "accounts" {
  description = "AWS accounts map"
  type        = map(string)
}

variable "admin_email" {
  type = string
}

variable "admin_user_name" {
  type    = string
  default = "denys"
}
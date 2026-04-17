variable "app_base_url" {
  type        = string
  description = "Example: https://unshieldedhollow.com"
  default = "https://unshieldedhero.click"
}

variable "cognito_domain_prefix" {
  type = string
  description = "This the part of the domain that creates an AWS hosted cognito login domain"
  default = "unshieldedhero-auth"
}

variable "flask_secret_key" {
  type      = string
  sensitive = true
  default = "6o9xlntezupsumy0jwohkzt26xfyp5qjco8dsbm2xgconhs16y8mj38i33gdhu5qua98lw"
}

variable "root_domain_name" {
  description = "The domain name for the ALB"
  type        = string
  default     = "unshieldedhero.click"
}
variable "route53_domain_name" {
  description = "value"
  type        = string
  default     = "www.unshieldedhero.click"
}

variable "certificate_validation_method" {
  type    = string
  default = "DNS"
}

variable "db_password" {
  type    = string
  description = "Database Postgres Password"
  default = "ChangeMe123456!"
}
variable "db_username" {
  type    = string
  description = "Database Postgres Username"
  default = "superuser"
}
variable "db_name" {
    description = "This is the database name within the postgress instance"
    type = string
    default = "appdb"
}
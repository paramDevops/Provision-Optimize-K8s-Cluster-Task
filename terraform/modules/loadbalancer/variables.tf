
variable "name" {
  type = string
}
variable "instances" {
  description = "EC2 instances"
  type        = list(string)
}
variable "additional_tags" {
  type = map(any)
}
variable "acm_cert_arn" {
  type = string
}

variable "frontend_subnet_ids" {
  description = "The frontend_subnet_ids"
  type        = list(string)
}

variable "vpc_id" {
  description = "The vpc"
  type        = string
}

variable "zone_name" {
  description = "The zone name"
  type        = string
}

variable "domain_name" {
  description = "The domain name"
  type        = string
}



variable "aws_region" {
  description = "The AWS region where the infrastructure will be deployed for the dev environment."
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "The vpc"
  type        = string
}

variable "frontend_subnet_ids" {
  description = "The frontend_subnet_ids"
  type        = list(string)
}

variable "ami_id" {
  type = string
}

variable "ec2_instance_type" {
  type = string
}
variable "name" {
  type = string
}

variable "infrastructure_version" {
  type    = string
  default = "N.A"
}

variable "instance_type" {
  description = "The instance type for the EC2 instances in the dev environment."
  type        = string
  default     = "t2.micro"
}
variable "additional_tags" {
  type = map(any)
}
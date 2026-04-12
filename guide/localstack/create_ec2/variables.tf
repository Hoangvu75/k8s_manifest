variable "localstack_endpoint" {
  type        = string
  description = "Gateway LocalStack (HTTPS Ingress hoặc http://localhost:4566)"
  default     = "https://localstack.hoangvu75.space"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_access_key_id" {
  type      = string
  default   = "test"
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  default   = "test"
  sensitive = true
}

variable "ec2_ami" {
  type        = string
  description = "AMI do LocalStack tải sẵn (Docker). Xem doc: Ubuntu 22.04 ami-df5de72bdb3b, AL2023 ami-024f768332f0, AL2 ami-07b643b5e45e. Liệt kê: awslocal ec2 describe-images --filters Name=tag:ec2_vm_manager,Values=docker"
  default     = "ami-df5de72bdb3b"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "name_prefix" {
  type    = string
  default = "ls-demo"
}

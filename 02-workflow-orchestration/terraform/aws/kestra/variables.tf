variable "aws_region" {
  default = "us-east-1"
}

variable "instance_name" {
  default = "ubuntu-24-ssm-node"
}

variable "allowed_ssh_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "allowed_app_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}
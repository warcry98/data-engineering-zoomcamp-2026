terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.20, <= 5.29"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------
# Ubuntu 24.04 LTS (Noble)
# -----------------------------
data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "this" {
  name        = "ubuntu-24-sg"
  description = "SSM + App + DB ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  ingress {
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = var.allowed_app_cidr
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_app_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "this" {
  ami                  = data.aws_ami.ubuntu_2404.id
  instance_type        = "t3.medium"
  iam_instance_profile = aws_iam_instance_profile.this.name

  vpc_security_group_ids = [
    aws_security_group.this.id
  ]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = file("${path.module}/bootstrap.sh")

  tags = {
    Name = var.instance_name
  }
}
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
    from_port   = 8080
    to_port     = 8080
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

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt update -y
    apt upgrade -y

    # -----------------
    # UFW
    # -----------------
    apt install -y ufw
    ufw allow 22
    ufw allow 5432
    ufw allow 5433
    ufw allow 8080
    ufw --force enable

    # -----------------
    # Docker
    # -----------------
    apt install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu noble stable" \
      > /etc/apt/sources.list.d/docker.list

    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker

    # -----------------
    # CloudWatch Agent
    # -----------------
    apt install -y amazon-cloudwatch-agent

    cat <<'CWEOF' > /opt/aws/amazon-cloudwatch-agent/bin/config.json
    ${file("${path.module}/cloudwatch-agent.json")}
    CWEOF

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
      -s

    cd ~
    git clone https://github.com/warcry98/data-engineering-zoomcamp-2026.git
    cd ~/data-engineering-zoomcamp-2026/02-workflow-orchestration/kestra
    docker compose build
    docker compose up -d
  EOF

  tags = {
    Name = var.instance_name
  }
}
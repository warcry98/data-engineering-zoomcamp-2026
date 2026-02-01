#!/bin/bash
set -euxo pipefail

exec > /var/log/user-data.log 2>&1

apt update -y
apt upgrade -y

# Install Ansible
apt install -y ansible git ufw openjdk-21-jre git-lfs
ufw allow 22
ufw allow 8080
ufw allow 8085
ufw allow 5432
ufw allow 5433
ufw --force enable

# Clone repo
cd /home/ubuntu
git clone https://github.com/warcry98/data-engineering-zoomcamp-2026.git
chown -R ubuntu:ubuntu data-engineering-zoomcamp-2026

# Run Ansible locally
ansible-playbook \
  -c local \
  -i localhost, \
  data-engineering-zoomcamp-2026/02-workflow-orchestration/ansible/aws/kestra/site.yml
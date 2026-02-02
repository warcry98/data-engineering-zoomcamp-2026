#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1

# Wait for network
until ping -c 1 archive.ubuntu.com &>/dev/null; do
  sleep 3
done

# Wait for apt
until apt-get update; do
  sleep 5
done

# Install packages (NO apt upgrade)
apt-get install -y ansible git ufw openjdk-21-jre git-lfs

# Clone repo
cd /home/ubuntu
git clone https://github.com/warcry98/data-engineering-zoomcamp-2026.git
chown -R ubuntu:ubuntu data-engineering-zoomcamp-2026

# Run Ansible as ubuntu
sudo -u ubuntu ansible-playbook \
  -c local \
  -i localhost, \
  /home/ubuntu/data-engineering-zoomcamp-2026/02-workflow-orchestration/ansible/aws/windmill/site.yml

# Firewall LAST
ufw allow 22
ufw allow 8080
ufw allow 8085
ufw allow 5432
ufw allow 5433
ufw --force enable
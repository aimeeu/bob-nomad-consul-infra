#!/bin/bash
set -e

# Set hostname
hostnamectl set-hostname ${hostname}

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    curl \
    wget \
    unzip \
    jq \
    git \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Create consul user
useradd --system --home /etc/consul.d --shell /bin/false consul

# Create nomad directories
mkdir -p /opt/nomad/data
mkdir -p /opt/nomad/plugins
mkdir -p /etc/nomad.d

# Create consul directories
mkdir -p /opt/consul
mkdir -p /etc/consul.d

# Set proper permissions
chown -R consul:consul /opt/consul
chown -R consul:consul /etc/consul.d

# Signal completion
touch /var/lib/cloud/instance/boot-finished

# Made with Bob

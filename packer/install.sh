#!/bin/bash
set -x
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install --yes \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    apt-transport-https 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install --yes docker-ce docker-ce-cli containerd.io


# Install Nomad
curl -O https://releases.hashicorp.com/nomad/1.2.1/nomad_1.2.1_linux_amd64.zip
sudo unzip nomad_1.2.1_linux_amd64.zip -d /usr/local/bin

sudo mv /tmp/nomad.service /etc/systemd/system/nomad.service

# Install Consul 
curl -O https://releases.hashicorp.com/consul/1.3.1/consul_1.3.1_linux_amd64.zip
sudo unzip consul_1.3.1_linux_amd64.zip -d /usr/local/bin

sudo mv /tmp/consul.service /etc/systemd/system/consul.service


sudo systemctl daemon-reload
#!/usr/bin/env bash
set -euo pipefail

echo "-------------------------------------------------"
echo "                   1) PREREQS"
echo "-------------------------------------------------"
echo

echo "  1.1: Downloading Jenkins Dockerfile from GitHub Repo"
curl -fsSL https://raw.githubusercontent.com/ThatDudeAlex/invoice-manager-infrastructure/refs/heads/master/docker/jenkins/dockerfile \
  -o /opt/docker/jenkins/Dockerfile
echo

echo "  1.2: Downloading docker-compose from GitHub Repo"
curl -fsSL https://raw.githubusercontent.com/ThatDudeAlex/invoice-manager-infrastructure/refs/heads/master/docker/docker-compose.yml \
  -o /opt/docker/docker-compose.yml
echo

echo "-------------------------------------------------"
echo "    2) Start Jenkins & SonarQube Containers"
echo "-------------------------------------------------"
echo

echo "  2.1: Running docker compose"
sudo docker compose -f /opt/docker/docker-compose.yml up -d
echo

echo "-------------------------------------------------"
echo "             3) Start Tailscale VPN"
echo "-------------------------------------------------"
echo

echo "  3.1: Downloading tailscale & authenticate"
curl -fsSL https://tailscale.com/install.sh | sh
read -p "Press ENTER to start Tailscale authentication (opens a browser URL)" _
sudo tailscale up
echo

echo "  3.2: Enabling tailscale"
sudo tailscale funnel enable
echo

echo "  3.3: Started jenkins tailscale funnel on port 8080"
sudo tailscale funnel 8080
echo

echo "-------------------------------------------------"
echo "                    SUCCESS"
echo "-------------------------------------------------"
echo
echo "The CIDC VM has been succesfully initiated"
echo "You can now configure Jenkins through the tailscale url, and sonarqube from http://your-vm-ip:9000"


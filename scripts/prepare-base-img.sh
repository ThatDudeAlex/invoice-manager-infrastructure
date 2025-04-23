#!/usr/bin/env bash
set -euo pipefail

echo "-------------------------------------------------"
ehco "           1) SYSTEM UPDATE & PREREQS"
ehco "-------------------------------------------------"
echo

echo "  1.1: Updating system packages"
apt update && apt upgrade -y
echo

echo "  1.2: Installing basic tools - git, curl, zip, UFW, fail2ban, OpenSSH"
apt install -y git curl zip ufw fail2ban OpenSSH sudo
echo

echo "-------------------------------------------------"
ehco "             2) FIREWALL & FAIL2BAN"
echo "-------------------------------------------------"
echo

echo "  2.1: Configuring UFW to allow only SSH"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw --force enable
echo

echo "  2.2: Configuring Fail2Ban for SSH protection"
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/16 10.0.0.0/8
EOF

systemctl enable --now fail2ban
echo

echo "-------------------------------------------------"
echo "               3) SSHD HARDENING"
echo "-------------------------------------------------"
echo

echo "  3.1: Hardening SSH settings"
sshd_conf=/etc/ssh/sshd_config

# Disable root login and password auth
sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin no/' "$sshd_conf"
sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication no/' "$sshd_conf"
sed -ri 's/^#?ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication no/' "$sshd_conf"

systemctl restart ssh
echo

echo "-------------------------------------------------"
echo "         4) INSTALL DOCKER (NO PROMPT)"
echo "-------------------------------------------------"
echo

echo "  4.1: Installing packages needed to securely add Docker's repo"
apt install -y apt-transport-https ca-certificates gnupg lsb-release
echo

echo "  4.2: Add Dockers GPG key"
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo

echo "  4.3: Add Dockers official APT repository"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
echo

echo "  4.4: Updating again to pick up the new Docker repo"
apt update
echo

echo "  4.5: Installing Docker components - docker-ce docker-ce-cli containerd.io docker-compose-plugin"
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
echo

systemctl enable docker
echo

echo "-------------------------------------------------"
echo "                   5) CLEANUP"
echo "-------------------------------------------------"

echo "  4.1: Remove unused packages"
apt autoremove -y
apt clean
echo

echo "  4.2: Clear bash history"
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/*/.bash_history
echo

echo "  4.3: Clear logs"
find /var/log -type f -exec truncate -s 0 {} \;
echo

echo "  4.4: Remove old DHCP leases"
rm -f /var/lib/dhcp/*
echo

echo "  4.5: Reset hostname"
hostnamectl set-hostname localhost
echo

echo "-------------------------------------------------"
echo "                    SUCCESS"
echo "-------------------------------------------------"
echo
echo "  Setup of base image template complete"
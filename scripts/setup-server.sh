#!/usr/bin/env bash
# Task 05 + Task 06 server setup for Ubuntu (run with: sudo bash scripts/setup-server.sh)
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo"; exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_USER="${SUDO_USER:-ubuntu}"

echo "==> Adding 2GB swap (small servers need it for Prometheus/Grafana)"
if ! swapon --show | grep -q swapfile; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi

echo "==> Installing packages"
apt-get update -y
apt-get install -y nginx ufw openssl curl git

echo "==> Installing Docker + Compose plugin"
curl -fsSL https://get.docker.com | sh

echo "==> Creating non-root 'deploy' user (key-based login only)"
id deploy &>/dev/null || adduser --disabled-password --gecos "" deploy
usermod -aG docker deploy
mkdir -p /home/deploy/.ssh
if [ -f "/home/$SRC_USER/.ssh/authorized_keys" ]; then
  cp "/home/$SRC_USER/.ssh/authorized_keys" /home/deploy/.ssh/authorized_keys
fi
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys 2>/dev/null || true

echo "==> Hardening SSH (disable password login + root login)"
cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'CONF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
CONF
sshd -t
systemctl reload ssh || systemctl reload sshd

echo "==> Configuring UFW firewall (only 22, 80, 443)"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> Creating self-signed SSL certificate"
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/C=IN/ST=Maharashtra/L=Pune/O=Capstone/CN=localhost"

echo "==> Installing Nginx reverse proxy config"
cp "$REPO_DIR/nginx/nginx.conf" /etc/nginx/sites-available/devops-capstone
ln -sf /etc/nginx/sites-available/devops-capstone /etc/nginx/sites-enabled/devops-capstone
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "==> DONE. Now run: sudo bash scripts/deploy.sh"

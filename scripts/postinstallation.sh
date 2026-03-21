#!/usr/bin/env bash

set -e

echo "🚀 Starting post-install setup..."

# -------------------------------
# VARIABLES (EDIT IF NEEDED)
# -------------------------------
USER_NAME=$(whoami)
DATA_ROOT="/mnt/cache/DATA"
DOCKER_DIR="$DATA_ROOT/docker"

# -------------------------------
# UPDATE SYSTEM
# -------------------------------
echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

# -------------------------------
# INSTALL BASIC TOOLS
# -------------------------------
echo "🧰 Installing basic packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    ca-certificates \
    gnupg \
    lsb-release \
    openssh-server

sudo systemctl enable --now ssh

# -------------------------------
# CREATE DIRECTORY STRUCTURE
# -------------------------------
echo "📁 Creating folder structure..."
sudo mkdir -p $DATA_ROOT/{docker,appdata,media,downloads,system/usb/{state,logs},backups/usb_imports}

# -------------------------------
# FIX PERMISSIONS
# -------------------------------
echo "🔐 Setting permissions..."
sudo chown -R $USER_NAME:$USER_NAME $DATA_ROOT
sudo chmod -R 775 $DATA_ROOT

# -------------------------------
# INSTALL TAILSCALE
# -------------------------------
echo "🌐 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "👉 Run 'sudo tailscale up' after script completes"

# -------------------------------
# INSTALL DOCKER
# -------------------------------
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sh

sudo usermod -aG docker $USER_NAME

# -------------------------------
# CONFIGURE DOCKER STORAGE
# -------------------------------
echo "⚙️ Configuring Docker storage..."

sudo systemctl stop docker || true

sudo mkdir -p $DOCKER_DIR

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "$DOCKER_DIR"
}
EOF

sudo systemctl daemon-reexec
sudo systemctl start docker

# -------------------------------
# INSTALL DOCKER COMPOSE
# -------------------------------
echo "🧩 Installing Docker Compose..."
sudo apt install -y docker-compose-plugin

# -------------------------------
# VERIFY DOCKER
# -------------------------------
echo "✅ Verifying Docker..."
docker info | grep "Docker Root Dir" || true

# -------------------------------
# INSTALL CASAOS
# -------------------------------
echo "🏠 Installing CasaOS..."
curl -fsSL https://get.casaos.io | sudo bash

# -------------------------------
# FINAL MESSAGE
# -------------------------------
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Log out & log back in (for docker group)"
echo "2. Run: sudo tailscale up"
echo "3. Open CasaOS: http://<your-server-ip>"
echo ""
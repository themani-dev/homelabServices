#!/usr/bin/env bash

set -e

# -------------------------------
# TERMINAL COLORS & STYLES
# -------------------------------
BOLD="$(tput bold 2>/dev/null || echo '')"
GREY="$(tput setaf 245 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

# -------------------------------
# UTILITY FUNCTIONS
# -------------------------------
print_header() {
    clear
    echo -e "${BOLD}${BLUE}==================================================${RESET}"
    echo -e "${BOLD}${BLUE}       HOMELAB POST-INSTALLATION SETUP           ${RESET}"
    echo -e "${BOLD}${BLUE}==================================================${RESET}"
    echo ""
}

print_step() {
    local step_num=$1
    local total_steps=$2
    local message=$3
    echo -e "${BOLD}${BLUE}[ ${step_num}/${total_steps} ] ${RESET}${BOLD}${message}${RESET}"
}

print_info() {
    echo -e "${GREY}  ➜ $1${RESET}"
}

print_success() {
    echo -e "${GREEN}  ✔ $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${RESET}"
}

print_error() {
    echo -e "${RED}  ✖ $1${RESET}"
}

print_separator() {
    echo -e "${GREY}--------------------------------------------------${RESET}"
}

# -------------------------------
# INITIALIZATION
# -------------------------------
TOTAL_STEPS=11
CURRENT_STEP=0

print_header

# -------------------------------
# VARIABLES (EDIT IF NEEDED)
# -------------------------------
USER_NAME=$(whoami)
DATA_ROOT="/mnt/cache/DATA"
DOCKER_DIR="$DATA_ROOT/docker"

# -------------------------------
# UPDATE SYSTEM
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Updating System"
print_info "Refreshing package lists and upgrading installed packages..."
sudo apt update && sudo apt upgrade -y
print_success "System updated successfully"
print_separator

# -------------------------------
# INSTALL BASIC TOOLS
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Installing Core Utilities"
print_info "Installing essential networking and system tools..."
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
print_success "Core utilities installed and SSH enabled"
print_separator

# -------------------------------
# CREATE DIRECTORY STRUCTURE
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Creating Directory Structure"
print_info "Creating required folders in $DATA_ROOT..."
sudo mkdir -p $DATA_ROOT/{docker,appdata,media,downloads,system/usb/{state,logs},backups/usb_imports}
print_success "Directory structure created"
print_separator

# -------------------------------
# FIX PERMISSIONS
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Configuring Permissions"
print_info "Setting ownership and permissions for $DATA_ROOT..."
sudo chown -R $USER_NAME:$USER_NAME $DATA_ROOT
sudo chmod -R 775 $DATA_ROOT
print_success "Permissions configured for $USER_NAME"
print_separator

# -------------------------------
# INSTALL TAILSCALE
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Installing Tailscale"
print_info "Downloading and executing Tailscale installer..."
curl -fsSL https://tailscale.com/install.sh | sh
print_warning "Action Required: Run 'sudo tailscale up' after this script finishes."
print_success "Tailscale installation complete"
print_separator

# -------------------------------
# INSTALL DOCKER
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Installing Docker"
print_info "Fetching Docker installation script..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER_NAME
print_success "Docker installed and user added to 'docker' group"
print_separator

# -------------------------------
# CONFIGURE DOCKER STORAGE
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Configuring Docker Storage"
print_info "Setting Docker data-root to $DOCKER_DIR..."

sudo systemctl stop docker || true
sudo mkdir -p $DOCKER_DIR

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "$DOCKER_DIR"
}
EOF

sudo systemctl daemon-reexec
sudo systemctl start docker
sleep 3
print_success "Docker storage relocated to $DOCKER_DIR"
print_separator

# -------------------------------
# INSTALL DOCKER COMPOSE
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Installing Docker Compose"
print_info "Adding Docker Compose plugin via apt..."
sudo apt install -y docker-compose-plugin
print_success "Docker Compose installed"
print_separator

# -------------------------------
# VERIFY DOCKER
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Verifying Docker Installation"
DOCKER_ROOT=$(docker info 2>/dev/null | grep "Docker Root Dir" | awk '{print $NF}')
if [ "$DOCKER_ROOT" == "$DOCKER_DIR" ]; then
    print_success "Verified: Docker Root is correctly set to $DOCKER_ROOT"
else
    print_warning "Note: Docker Root check returned: ${DOCKER_ROOT:-Unknown}"
fi
print_separator

# -------------------------------
# INSTALL CASAOS
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Installing CasaOS"
print_info "Starting CasaOS automated installation..."
curl -fsSL https://get.casaos.io | sudo bash
print_success "CasaOS installation complete"
print_separator

# -------------------------------
# FINAL MESSAGE
# -------------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Setup Complete"
echo ""
echo -e "${BOLD}${GREEN}🎉 Congratulations! Your homelab is ready.${RESET}"
echo ""
echo -e "${BOLD}Next steps to finalize:${RESET}"
echo -e "  1. ${BOLD}Logout & Login${RESET} (Required for Docker group permissions)"
echo -e "  2. ${BOLD}sudo tailscale up${RESET} (Connect your node to the tailnet)"
echo -e "  3. ${BOLD}Visit CasaOS:${RESET} http://$(hostname -I | awk '{print $1}')"
echo ""
echo -e "${GREY}Thank you for using the homelab setup script!${RESET}"
echo ""
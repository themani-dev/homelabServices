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
    echo -e "${BOLD}${BLUE}       CONTAINERD STORAGE MIGRATION              ${RESET}"
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
TOTAL_STEPS=8
CURRENT_STEP=0

print_header

# -----------------------------
# CONFIG
# -----------------------------
SRC="/var/lib/containerd"
DEST="/mnt/cache/DATA/containerd"

# -----------------------------
# PRECHECK
# -----------------------------
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Pre-flight Checks"

if [ ! -d "$SRC" ]; then
    print_error "Source directory $SRC does not exist"
    exit 1
fi

CURRENT_SIZE=$(sudo du -sh "$SRC" | awk '{print $1}')
print_info "Current containerd storage size: $CURRENT_SIZE"
print_success "Ready for migration"
print_separator

# -----------------------------
# STOP SERVICES
# -----------------------------
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Stopping Services"
print_info "Stopping Docker & containerd to prevent data corruption..."
sudo systemctl stop docker || true
sudo systemctl stop containerd || true
print_success "Services stopped"
print_separator

# -----------------------------
# CREATE DEST
# -----------------------------
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Preparing Destination"
print_info "Creating migration target: $DEST..."
sudo mkdir -p "$DEST"
print_success "Destination ready"
print_separator

# -----------------------------
# COPY DATA
# -----------------------------
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Migrating Data"
print_info "Executing rsync (this may take a while depending on size)..."
sudo rsync -aP "$SRC/" "$DEST/"
print_success "Data transfer complete"
print_separator

# -----------------------------
# CONFIGURE CONTAINERD
# -----------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Configuring containerd"
print_info "Updating config at /etc/containerd/config.toml..."

if [ ! -f /etc/containerd/config.toml ] || [ ! -s /etc/containerd/config.toml ]; then
    print_warning "Config file missing or empty. Generating default..."
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
fi

sudo sed -i "s|root = \".*\"|root = \"$DEST\"|" /etc/containerd/config.toml
print_success "Configuration updated to use $DEST"
print_separator

# -----------------------------
# RESTART SERVICES
# -----------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Restarting Services"
print_info "Reloading systemd and starting containerd/docker..."
sudo systemctl daemon-reexec
sudo systemctl start containerd
sudo systemctl start docker
print_success "Services restored"
print_separator

# -----------------------------
# VERIFY
# -----------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Verificaton"
NEW_ROOT=$(grep "root =" /etc/containerd/config.toml | awk -F'"' '{print $2}')
if [ "$NEW_ROOT" == "$DEST" ]; then
    print_success "Verified: containerd root set to $NEW_ROOT"
else
    print_error "Verification FAILED: config shows $NEW_ROOT"
fi

NEW_SIZE=$(sudo du -sh "$DEST" | awk '{print $1}')
print_info "New storage location size: $NEW_SIZE"
print_separator

# -----------------------------
# CLEANUP
# -----------------------------
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Cleanup"
print_info "Removing legacy data from $SRC..."
sudo rm -rf "$SRC"/*
print_success "Cleanup finished"
print_separator

# -----------------------------
# SUMMARY
# -----------------------------
echo ""
echo -e "${BOLD}${GREEN}🎉 Migration Successful!${RESET}"
echo ""
echo -e "${BOLD}Storage Statistics:${RESET}"
echo -e "  ➜ New Location: ${BOLD}$DEST${RESET}"
echo -e "  ➜ Root FS Freed: ${BOLD}$CURRENT_SIZE${RESET}"
echo ""
print_info "Current /var usage:"
sudo du -sh /var
echo ""
print_info "Disk usage overview:"
df -h | grep -E '^/dev/|Filesystem|/mnt/cache'
echo ""
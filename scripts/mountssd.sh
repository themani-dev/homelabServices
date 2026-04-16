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
    echo -e "${BOLD}${BLUE}         SSD & STORAGE MOUNT SETUP               ${RESET}"
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

echo -e "${BOLD}${YELLOW}👉 IMPORTANT: Run 'lsblk -f' to confirm UUIDs before proceeding.${RESET}"
echo ""

# =========================================================
# 🔁 CONFIGURATION (EDIT THESE VALUES)
# =========================================================

# Disk 1 - SSD
SSD1_UUID="5c7ec71f-b289-49fa-8d73-4dff8a1a20a8"
SSD1_MOUNT="/mnt/cache"
SSD1_FS="ext4"        # ext4 | ntfs-3g | exfat

# Disk 2 - HDD
SSD2_UUID="fc15013f-acc6-4e16-8994-53a0bad298ae"
SSD2_MOUNT="/mnt/storage"
SSD2_FS="ext4"        # ext4 | ntfs-3g | exfat


# USB mount
USB_MOUNT="/mnt/usb"
USB_FS="ext4"        # ext4 | ntfs-3g | exfat

# User (for permissions)
USER_NAME=$(whoami)
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# =========================================================
# 🧰 INSTALL FILESYSTEM SUPPORT (if needed)
# =========================================================
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Installing Filesystem Support"
print_info "Updating package lists..."
sudo apt update

if [[ "$SSD1_FS" == "ntfs-3g" || "$SSD2_FS" == "ntfs-3g" ]]; then
    print_info "Installing ntfs-3g..."
    sudo apt install -y ntfs-3g
fi

if [[ "$SSD1_FS" == "exfat" || "$SSD2_FS" == "exfat" ]]; then
    print_info "Installing exfat support..."
    sudo apt install -y exfat-fuse exfatprogs
fi
print_success "Filesystem support verified"
print_separator

# =========================================================
# 📁 CREATE MOUNT POINTS
# =========================================================
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Creating Mount Points"
print_info "Creating directories for $SSD1_MOUNT, $SSD2_MOUNT, and $USB_MOUNT..."
sudo mkdir -p "$SSD1_MOUNT"
sudo mkdir -p "$SSD2_MOUNT"
sudo mkdir -p "$USB_MOUNT"
print_success "Mount directories created"
print_separator

# =========================================================
# 🧾 BACKUP FSTAB
# =========================================================
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Backing up fstab"
BACKUP_FILE="/etc/fstab.backup.$(date +%s)"
print_info "Creating backup at $BACKUP_FILE..."
sudo cp /etc/fstab "$BACKUP_FILE"
print_success "Backup created successfully"
print_separator

# =========================================================
# ✍️ ADD TO FSTAB
# =========================================================
((++CURRENT_STEP))
print_step $CURRENT_STEP $TOTAL_STEPS "Updating /etc/fstab"

add_fstab_entry () {
    local UUID=$1
    local MOUNT=$2
    local FS=$3

    if grep -q "$UUID" /etc/fstab; then
        print_warning "Entry for $UUID already exists, skipping..."
        return
    fi

    if [[ "$FS" == "ext4" ]]; then
        OPTIONS="defaults,nofail"
    elif [[ "$FS" == "ntfs-3g" || "$FS" == "exfat" ]]; then
        OPTIONS="defaults,nofail,uid=$USER_ID,gid=$GROUP_ID"
    else
        print_error "Unsupported filesystem: $FS"
        exit 1
    fi

    print_info "Adding entry for $MOUNT (UUID: $UUID)..."
    echo "UUID=$UUID  $MOUNT  $FS  $OPTIONS  0  2" | sudo tee -a /etc/fstab
}

add_fstab_entry "$SSD1_UUID" "$SSD1_MOUNT" "$SSD1_FS"
add_fstab_entry "$SSD2_UUID" "$SSD2_MOUNT" "$SSD2_FS"
print_success "fstab updated"
print_separator

# =========================================================
# 🔄 MOUNT ALL
# =========================================================
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Mounting Drives"
print_info "Executing 'mount -a'..."
sudo mount -a
print_success "Drives mounted"
print_separator

# =========================================================
# 🔍 VERIFY
# =========================================================
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Verifying Mounts"

if mount | grep -q "$SSD1_MOUNT"; then
    print_success "SSD1 mounted at $SSD1_MOUNT"
else
    print_error "SSD1 mount failed"
fi

if mount | grep -q "$SSD2_MOUNT"; then
    print_success "SSD2 mounted at $SSD2_MOUNT"
else
    print_error "SSD2 mount failed"
fi
print_separator

# =========================================================
# 🔐 FIX PERMISSIONS
# =========================================================
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Configuring Permissions"
print_info "Setting owner to $USER_NAME for mount points..."
sudo chown -R $USER_NAME:$USER_NAME "$SSD1_MOUNT" "$SSD2_MOUNT" "$USB_MOUNT"
print_success "Permissions updated"
print_separator

# =========================================================
# 🧪 WRITE TEST
# =========================================================
((CURRENT_STEP++))
print_step $CURRENT_STEP $TOTAL_STEPS "Testing Write Access"

if touch "$SSD1_MOUNT/testfile" 2>/dev/null; then
    rm "$SSD1_MOUNT/testfile"
    print_success "SSD1 write check OK"
else
    print_error "SSD1 write check FAILED"
fi

if touch "$SSD2_MOUNT/testfile" 2>/dev/null; then
    rm "$SSD2_MOUNT/testfile"
    print_success "SSD2 write check OK"
else
    print_error "SSD2 write check FAILED"
fi
print_separator

# =========================================================
# 🏁 FINAL MESSAGE
# =========================================================
echo ""
echo -e "${BOLD}${GREEN}🎉 Mount setup complete!${RESET}"
echo ""
echo -e "${BOLD}Recommended next step:${RESET}"
echo -e "  ➜ Run ${BOLD}sudo reboot${RESET} to verify persistent automount."
echo ""
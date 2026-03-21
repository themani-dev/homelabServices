#!/usr/bin/env bash

set -e
echo ""
echo "👉 Run 'lsblk -f' to confirm UUIDs before using script"
echo ""
echo "🔧 Starting SSD mount setup..."

# =========================================================
# 🔁 CONFIGURATION (EDIT THESE VALUES)
# =========================================================

# Disk 1 - SSD
SSD1_UUID="REPLACE_WITH_UUID_1"
SSD1_MOUNT="/mnt/cache"
SSD1_FS="ext4"        # ext4 | ntfs-3g | exfat

# Disk 2 - HDD
SSD2_UUID="REPLACE_WITH_UUID_2"
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

echo "📦 Installing filesystem support..."
sudo apt update

if [[ "$SSD1_FS" == "ntfs-3g" || "$SSD2_FS" == "ntfs-3g" ]]; then
    sudo apt install -y ntfs-3g
fi

if [[ "$SSD1_FS" == "exfat" || "$SSD2_FS" == "exfat" ]]; then
    sudo apt install -y exfat-fuse exfatprogs
fi

# =========================================================
# 📁 CREATE MOUNT POINTS
# =========================================================

echo "📁 Creating mount directories..."
sudo mkdir -p "$SSD1_MOUNT"
sudo mkdir -p "$SSD2_MOUNT"
sudo mkdir -p "$USB_MOUNT"


# =========================================================
# 🧾 BACKUP FSTAB
# =========================================================

echo "💾 Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup.$(date +%s)

# =========================================================
# 🔗 ADD TO FSTAB
# =========================================================

echo "✍️ Updating /etc/fstab..."

add_fstab_entry () {
    local UUID=$1
    local MOUNT=$2
    local FS=$3

    if grep -q "$UUID" /etc/fstab; then
        echo "⚠️ Entry for $UUID already exists, skipping..."
        return
    fi

    if [[ "$FS" == "ext4" ]]; then
        OPTIONS="defaults,nofail"
    elif [[ "$FS" == "ntfs-3g" || "$FS" == "exfat" ]]; then
        OPTIONS="defaults,nofail,uid=$USER_ID,gid=$GROUP_ID"
    else
        echo "❌ Unsupported filesystem: $FS"
        exit 1
    fi

    echo "UUID=$UUID  $MOUNT  $FS  $OPTIONS  0  2" | sudo tee -a /etc/fstab
}

add_fstab_entry "$SSD1_UUID" "$SSD1_MOUNT" "$SSD1_FS"
add_fstab_entry "$SSD2_UUID" "$SSD2_MOUNT" "$SSD2_FS"

# =========================================================
# 🔄 MOUNT ALL
# =========================================================

echo "🔄 Mounting drives..."
sudo mount -a

# =========================================================
# 🔍 VERIFY
# =========================================================

echo "🔍 Verifying mounts..."

if mount | grep -q "$SSD1_MOUNT"; then
    echo "✅ SSD1 mounted at $SSD1_MOUNT"
else
    echo "❌ SSD1 mount failed"
fi

if mount | grep -q "$SSD2_MOUNT"; then
    echo "✅ SSD2 mounted at $SSD2_MOUNT"
else
    echo "❌ SSD2 mount failed"
fi

# =========================================================
# 🔐 FIX PERMISSIONS
# =========================================================

echo "🔐 Setting permissions..."
sudo chown -R $USER_NAME:$USER_NAME "$SSD1_MOUNT" "$SSD2_MOUNT" "$USB_MOUNT"

# =========================================================
# 🧪 WRITE TEST
# =========================================================

echo "🧪 Testing write access..."

touch "$SSD1_MOUNT/testfile" && echo "✅ SSD1 write OK" || echo "❌ SSD1 write FAILED"
touch "$SSD2_MOUNT/testfile" && echo "✅ SSD2 write OK" || echo "❌ SSD2 write FAILED"

echo ""
echo "🎉 Mount setup complete!"
echo ""
echo "👉 Reboot test recommended: sudo reboot"
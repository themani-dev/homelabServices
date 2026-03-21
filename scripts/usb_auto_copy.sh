#!/usr/bin/env bash


## Copy this file to /usr/local/bin/usb_auto_copy.sh
## Copy the env file to /etc/usb_auto_copy.env

ACTION=$1
DEVICE=$2

# ------------------------------------------------
# LOAD ENV
# ------------------------------------------------
ENV_FILE="/etc/usb_auto_copy.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Missing env file: $ENV_FILE"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# Validate required vars
REQUIRED_VARS=("SYSTEM_BASE" "DEST_BASE")

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Missing required env variable: $var"
        exit 1
    fi
done

# ------------------------------------------------
# CONFIG
# ------------------------------------------------
MOUNT_BASE="/mnt"
USB_PREFIX="usb"
DEST_BASE="$DEST_BASE"

SYSTEM_BASE="$SYSTEM_BASE"
STATE_DIR="$SYSTEM_BASE/usb/state"
LOGFILE="$SYSTEM_BASE/usb/logs/usb-copy.log"

SIZE_LIMIT_GB=300
USER_ID=1000
GROUP_ID=1000

# Notifications
TELEGRAM_BOT_TOKEN="REPLACE_TELEGRAM_TOKEN"
TELEGRAM_CHAT_ID="REPLACE_CHAT_ID"

SLACK_WEBHOOK_URL="REPLACE_SLACK_WEBHOOK"

mkdir -p "$STATE_DIR"
mkdir -p "$(dirname $LOGFILE)"

log() {
    MSG="$(date '+%Y-%m-%d %H:%M:%S'): $1"
    echo "$MSG" >> "$LOGFILE"
}

notify() {
    MESSAGE="$1"

    # Telegram
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="$MESSAGE" >/dev/null
    fi

    # Slack
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$MESSAGE\"}" \
            "$SLACK_WEBHOOK_URL" >/dev/null
    fi
}

# ------------------------------------------------
# FIND AVAILABLE MOUNT SLOT
# ------------------------------------------------
find_mount_slot() {
    for i in $(seq 1 10); do
        SLOT="$MOUNT_BASE/${USB_PREFIX}${i}"
        if ! mount | grep -q "$SLOT"; then
            echo "$SLOT"
            return
        fi
    done
}

# ------------------------------------------------
# HASH FUNCTION
# ------------------------------------------------
generate_usb_hash() {
    find "$1" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
}

# ------------------------------------------------
# PARALLEL RSYNC
# ------------------------------------------------
parallel_rsync() {
    SRC="$1"
    DEST="$2"

    find "$SRC" -type f | while read -r file; do
        echo "$file"
    done | xargs -P 4 -I {} rsync -a --relative "{}" "$DEST"
}

# ------------------------------------------------
# USB INSERT
# ------------------------------------------------
if [ "$ACTION" == "add" ]; then
    log "USB detected: $DEVICE"
    sleep 3

    MOUNT_POINT=$(find_mount_slot)

    if [ -z "$MOUNT_POINT" ]; then
        log "No mount slot available"
        exit 1
    fi

    mkdir -p "$MOUNT_POINT"

    mount -o rw,nosuid,nodev,uid=$USER_ID,gid=$GROUP_ID "$DEVICE" "$MOUNT_POINT"

    if [ $? -ne 0 ]; then
        log "Mount failed"
        exit 1
    fi

    log "Mounted at $MOUNT_POINT"
    sleep 3

    # SIZE CHECK
    USB_SIZE_GB=$(du -sBG "$MOUNT_POINT" 2>/dev/null | cut -f1 | sed 's/G//')
    log "USB size: ${USB_SIZE_GB}GB"

    if [ "$USB_SIZE_GB" -gt "$SIZE_LIMIT_GB" ]; then
        log "Skipped (size > ${SIZE_LIMIT_GB}GB)"
        notify "USB skipped (too large): ${USB_SIZE_GB}GB"
        exit 0
    fi

    # HASH CHECK
    log "Generating hash..."
    USB_HASH=$(generate_usb_hash "$MOUNT_POINT")
    HASH_FILE="$STATE_DIR/$USB_HASH"

    if [ -f "$HASH_FILE" ]; then
        log "Duplicate detected"
        notify "Duplicate USB skipped"
        exit 0
    fi

    # COPY
    TODAY=$(date +%Y-%m-%d)
    DESTINATION="$DEST_BASE/$TODAY/$USB_HASH"

    mkdir -p "$DESTINATION"

    log "Starting parallel copy..."
    START_TIME=$(date +%s)

    parallel_rsync "$MOUNT_POINT" "$DESTINATION" >> "$LOGFILE" 2>&1

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    log "Copy finished in ${DURATION}s"

    # VERIFY
    log "Verifying integrity..."
    SRC_HASH=$(generate_usb_hash "$MOUNT_POINT")
    DEST_HASH=$(generate_usb_hash "$DESTINATION")

    if [ "$SRC_HASH" == "$DEST_HASH" ]; then
        log "Integrity OK"
        touch "$HASH_FILE"
        notify "USB copy SUCCESS ✅ (${USB_SIZE_GB}GB, ${DURATION}s)"
    else
        log "Integrity FAILED"
        notify "USB copy FAILED ❌"
    fi
fi

# ------------------------------------------------
# USB REMOVE
# ------------------------------------------------
if [ "$ACTION" == "remove" ]; then
    log "USB removed: $DEVICE"

    MOUNT_POINT=$(mount | grep "$DEVICE" | awk '{print $3}')

    if [ -n "$MOUNT_POINT" ]; then
        umount "$MOUNT_POINT"
        log "Unmounted $MOUNT_POINT"
    fi
fi
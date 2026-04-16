#!/usr/bin/env bash

# ------------------------------------------------
# TERMINAL COLORS & STYLES (for interactive use)
# ------------------------------------------------
if [ -t 1 ]; then
    BOLD="$(tput bold 2>/dev/null || echo '')"
    GREY="$(tput setaf 245 2>/dev/null || echo '')"
    BLUE="$(tput setaf 4 2>/dev/null || echo '')"
    GREEN="$(tput setaf 2 2>/dev/null || echo '')"
    YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
    RED="$(tput setaf 1 2>/dev/null || echo '')"
    RESET="$(tput sgr0 2>/dev/null || echo '')"
else
    BOLD="" GREY="" BLUE="" GREEN="" YELLOW="" RED="" RESET=""
fi

# ------------------------------------------------
# DOCUMENTATION & SETUP STEPS (Informative)
# ------------------------------------------------
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo -e "${BOLD}${BLUE}=== USB Auto-Copy Setup Guide ===${RESET}"
    echo -e "${BOLD}Pre-Deployment:${RESET}"
    echo -e "  1. Copy script:  ${GREY}sudo cp $0 /usr/local/bin/usb_auto_copy.sh${RESET}"
    echo -e "  2. Copy env:     ${GREY}sudo cp usb_auto_copy.env /etc/usb_auto_copy.env${RESET}"
    echo -e "  3. Permissions:  ${GREY}sudo chmod +x /usr/local/bin/usb_auto_copy.sh${RESET}"
    echo -e "  4. Config Sec:   ${GREY}sudo chmod 600 /etc/usb_auto_copy.env${RESET}"
    echo ""
    echo -e "${BOLD}Post-Deployment (udev rule):${RESET}"
    echo -e "  File path: ${GREY}/etc/udev/rules.d/99-usb-automount.rules${RESET}"
    echo -e "  Content:${GREY}"
    echo -e "    ACTION==\"add\", SUBSYSTEM==\"block\", ENV{ID_BUS}==\"usb\", ENV{DEVTYPE}==\"partition\", RUN+=\"/usr/local/bin/usb_auto_copy.sh add /dev/%k\""
    echo -e "    ACTION==\"remove\", SUBSYSTEM==\"block\", ENV{ID_BUS}==\"usb\", ENV{DEVTYPE}==\"partition\", RUN+=\"/usr/local/bin/usb_auto_copy.sh remove /dev/%k\""
    echo -e "${RESET}"
    echo -e "  Reload rules: ${GREY}sudo udevadm control --reload-rules && sudo udevadm trigger${RESET}"
    exit 0
fi

# ------------------------------------------------
# UTILITY FUNCTIONS
# ------------------------------------------------
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local tag="[${level^^}]"
    
    # Log to file (plain text)
    echo "$timestamp $tag: $message" >> "$LOGFILE"

    # Print to terminal if interactive
    if [ -t 1 ]; then
        case ${level,,} in
            info)    color="$BLUE";   prefix="➜";;
            success) color="$GREEN";  prefix="✔";;
            warning) color="$YELLOW"; prefix="⚠";;
            error)   color="$RED";    prefix="✖";;
            *)       color="$RESET";  prefix="·";;
        esac
        echo -e "${color}${BOLD}${prefix} ${RESET}${BOLD}${message}${RESET}"
    fi
}

notify() {
    local msg="$1"
    # Telegram
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ] && [ "$TELEGRAM_BOT_TOKEN" != "REPLACE_TELEGRAM_TOKEN" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="$msg" >/dev/null
    fi
    # Slack
    if [ -n "$SLACK_WEBHOOK_URL" ] && [ "$SLACK_WEBHOOK_URL" != "REPLACE_SLACK_WEBHOOK" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$msg\"}" \
            "$SLACK_WEBHOOK_URL" >/dev/null
    fi
}

# ------------------------------------------------
# CORE ARGUMENTS
# ------------------------------------------------
ACTION=$1
DEVICE=$2

# ------------------------------------------------
# LOAD ENVIRONMENT CONFIG
# ------------------------------------------------
ENV_FILE="/etc/usb_auto_copy.env"

if [ ! -f "$ENV_FILE" ]; then
    # We don't have LOGFILE yet, so just echo
    echo -e "${RED}${BOLD}✖ Error: Missing environment file: $ENV_FILE${RESET}"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# Validate required vars
REQUIRED_VARS=("SYSTEM_BASE" "DEST_BASE")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}${BOLD}✖ Error: Missing required env variable: $var${RESET}"
        exit 1
    fi
done

# ------------------------------------------------
# CONFIGURATION
# ------------------------------------------------
MOUNT_BASE="/mnt"
USB_PREFIX="usb"

STATE_DIR="$SYSTEM_BASE/usb/state"
LOGFILE="$SYSTEM_BASE/usb/logs/usb-copy.log"

SIZE_LIMIT_GB=300
USER_ID=1000
GROUP_ID=1000

# Ensure directories exist
mkdir -p "$STATE_DIR"
mkdir -p "$(dirname $LOGFILE)"

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
# HASH GENERATION
# ------------------------------------------------
generate_usb_hash() {
    find "$1" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
}

# ------------------------------------------------
# PARALLEL RSYNC
# ------------------------------------------------
parallel_rsync() {
    local src="$1"
    local dest="$2"
    log "info" "Starting parallel copy..."
    find "$src" -type f | xargs -P 4 -I {} rsync -a --relative "{}" "$dest"
}

# ------------------------------------------------
# ACTION: ADD (USB INSERTED)
# ------------------------------------------------
if [ "$ACTION" == "add" ]; then
    log "info" "USB device detected: $DEVICE"
    sleep 3

    MOUNT_POINT=$(find_mount_slot)
    if [ -z "$MOUNT_POINT" ]; then
        log "error" "No available mount slots (limit 1-10)"
        exit 1
    fi

    mkdir -p "$MOUNT_POINT"
    log "info" "Attempting to mount $DEVICE at $MOUNT_POINT..."
    
    if mount -o rw,nosuid,nodev,uid=$USER_ID,gid=$GROUP_ID "$DEVICE" "$MOUNT_POINT"; then
        log "success" "Mounted successfully"
    else
        log "error" "Mount failed for $DEVICE"
        exit 1
    fi
    
    sleep 3

    # SIZE CHECK
    USB_SIZE_GB=$(du -sBG "$MOUNT_POINT" 2>/dev/null | cut -f1 | sed 's/G//')
    log "info" "Analysis: USB size is ${USB_SIZE_GB}GB"

    if [ "$USB_SIZE_GB" -gt "$SIZE_LIMIT_GB" ]; then
        log "warning" "Skipping copy: Size ${USB_SIZE_GB}GB exceeds limit (${SIZE_LIMIT_GB}GB)"
        notify "⚠️ USB skipped (too large): ${USB_SIZE_GB}GB"
        exit 0
    fi

    # HASH CHECK
    log "info" "Generating content signature..."
    USB_HASH=$(generate_usb_hash "$MOUNT_POINT")
    HASH_FILE="$STATE_DIR/$USB_HASH"

    if [ -f "$HASH_FILE" ]; then
        log "warning" "Duplicate USB detected (signature match). Skipping copy."
        notify "ℹ️ Duplicate USB skipped"
        exit 0
    fi

    # EXECUTE COPY
    TODAY=$(date +%Y-%m-%d)
    DESTINATION="$DEST_BASE/$TODAY/$USB_HASH"
    mkdir -p "$DESTINATION"

    START_TIME=$(date +%s)
    parallel_rsync "$MOUNT_POINT" "$DESTINATION" >> "$LOGFILE" 2>&1
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    log "success" "Copy finished in ${DURATION}s"

    # VERIFY INTEGRITY
    log "info" "Verifying data integrity..."
    DEST_HASH=$(generate_usb_hash "$DESTINATION")

    if [ "$USB_HASH" == "$DEST_HASH" ]; then
        log "success" "Integrity check passed (checksum valid)"
        touch "$HASH_FILE"
        notify "✅ USB copy SUCCESS (${USB_SIZE_GB}GB, ${DURATION}s)"
    else
        log "error" "Integrity checksum FAILED!"
        notify "❌ USB copy FAILED (Checksum mismatch)"
    fi
fi

# ------------------------------------------------
# ACTION: REMOVE (USB PULLED)
# ------------------------------------------------
if [ "$ACTION" == "remove" ]; then
    log "info" "USB removal detected: $DEVICE"
    MOUNT_POINT=$(mount | grep "$DEVICE" | awk '{print $3}')

    if [ -n "$MOUNT_POINT" ]; then
        if umount "$MOUNT_POINT"; then
            log "success" "Cleanly unmounted $MOUNT_POINT"
        else
            log "error" "Forceful removal: Could not unmount $MOUNT_POINT cleanly"
        fi
    fi
fi

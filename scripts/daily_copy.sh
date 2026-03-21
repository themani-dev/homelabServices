#!/bin/bash

SOURCE="/DATA/cache/usb_clone/ReadyToMove/"
DEST="/DATA/storage/backup/USB/"
LOGFILE="/var/log/daily_copy.log"

if [ "$(ls -A $SOURCE)" ]; then
    echo "$(date): Files found. Starting copy." >> $LOGFILE
    rsync -av --remove-source-files "$SOURCE/" "$DEST/" >> $LOGFILE 2>&1
    echo "$(date): Copy done." >> $LOGFILE
else
    echo "$(date): No files to copy." >> $LOGFILE
fi

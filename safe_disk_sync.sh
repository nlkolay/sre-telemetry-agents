# Rsync-обертка с контролем температуры диска
#!/bin/bash
SRC="/mnt/old_hdd/"
DEST="/mnt/new_hdd/"
MAX_TEMP=55

rsync -ahvP "$SRC" "$DEST" &
SYNC_PID=$!

while kill -0 $SYNC_PID 2>/dev/null; do
    TEMP=$(smartctl -A /dev/sdc | grep "Temperature_Celsius" | awk '{print $10}')
    if [[ "$TEMP" -gt "$MAX_TEMP" ]]; then
        echo "CRITICAL: HDD Temperature exceeded ${MAX_TEMP}C. Halting rsync to prevent hardware failure."
        kill -9 $SYNC_PID
        exit 1
    fi
    sleep 60
done

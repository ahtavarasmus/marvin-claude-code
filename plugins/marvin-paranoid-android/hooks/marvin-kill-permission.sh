#!/bin/bash
# Kill any still-playing or pending permission audio when a tool starts executing
# This cuts Marvin off when the user accepts a permission

input=$(cat)

# Set cancel marker FIRST - this closes the race window where the background
# subshell has already passed the pending-file check but hasn't started playing yet.
# The subshell checks this marker after starting playback and self-kills if set.
CANCEL_DIR="/tmp/marvin-permission-cancel"
mkdir -p "$CANCEL_DIR"
touch "$CANCEL_DIR/${PPID}"

# Cancel any pending (not yet playing) permission audio for this session
rm -f /tmp/marvin-permission-pending/${PPID}_* 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PID_FILE="$AUDIO_DIR/.permission_pid"

if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi

exit 0

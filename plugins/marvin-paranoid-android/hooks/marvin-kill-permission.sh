#!/bin/bash
# Kill any still-playing permission audio when a tool starts executing
# This cuts Marvin off when the user accepts a permission

input=$(cat)

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

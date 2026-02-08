#!/bin/bash
# Marvin reacts when permission is requested
# Skips AskUserQuestion and ExitPlanMode (they have dedicated hooks)
# Uses shuffled playlist (same approach as other hooks)

input=$(cat)

# Skip if this is an AskUserQuestion or ExitPlanMode - they have their own hooks
tool_name=$(echo "$input" | jq -r '.tool_name // .tool // ""' 2>/dev/null)
if [ "$tool_name" = "AskUserQuestion" ] || [ "$tool_name" = "ExitPlanMode" ]; then
    exit 0
fi

# Check config - skip if disabled
CONFIG="$HOME/.config/marvin/config.json"
if [ -f "$CONFIG" ] && [ "$(jq -r '.permission // true' "$CONFIG" 2>/dev/null)" = "false" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"

# Cooldown: skip if a permission clip played within the last 2 seconds
COOLDOWN_FILE="$AUDIO_DIR/.permission_cooldown"
if [ -f "$COOLDOWN_FILE" ]; then
    last=$(cat "$COOLDOWN_FILE" 2>/dev/null)
    now=$(date +%s)
    if [ -n "$last" ] && [ $((now - last)) -lt 2 ]; then
        exit 0
    fi
fi
date +%s > "$COOLDOWN_FILE"

PLAYLIST="$AUDIO_DIR/.permission_playlist"

if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_permission_*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    MARVIN_PID="$AUDIO_DIR/.marvin_pid"
    if [ -f "$MARVIN_PID" ]; then
        kill "$(cat "$MARVIN_PID" 2>/dev/null)" 2>/dev/null
    fi
    afplay "$clip" &>/dev/null &
    echo $! > "$MARVIN_PID"
    echo $! > "$AUDIO_DIR/.permission_pid"
    disown $!
fi

exit 0

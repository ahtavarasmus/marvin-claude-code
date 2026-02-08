#!/bin/bash
# Marvin the Paranoid Android - stop hook
# Marvin comments on your completed tasks with existential despair.
# Uses a shuffled playlist so every clip plays before any repeats.

# Read stdin (stop hook input) and check for loop prevention
input=$(cat)
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')
if [ "$stop_hook_active" = "true" ]; then
    exit 0
fi

# Check config - skip if disabled
CONFIG="$HOME/.config/marvin/config.json"
if [ -f "$CONFIG" ] && [ "$(jq -r '.stop // true' "$CONFIG" 2>/dev/null)" = "false" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PLAYLIST="$AUDIO_DIR/.playlist"

# If playlist is empty or missing, reshuffle all clips
if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_[0-9]*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

# Pop the first clip from the playlist
clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    MARVIN_PID="$AUDIO_DIR/.marvin_pid"
    if [ -f "$MARVIN_PID" ]; then
        kill "$(cat "$MARVIN_PID" 2>/dev/null)" 2>/dev/null
    fi
    afplay "$clip" </dev/null &>/dev/null &
    echo $! > "$MARVIN_PID"
    disown $!
fi

exit 0

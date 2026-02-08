#!/bin/bash
# Marvin greets you when a session starts
# Uses shuffled playlist (same approach as other hooks)

input=$(cat)

# Check config - skip if disabled
CONFIG="$HOME/.config/marvin/config.json"
if [ -f "$CONFIG" ] && [ "$(jq -r '.session // true' "$CONFIG" 2>/dev/null)" = "false" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PLAYLIST="$AUDIO_DIR/.session_playlist"

if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_session_*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    afplay "$clip" &
fi

exit 0

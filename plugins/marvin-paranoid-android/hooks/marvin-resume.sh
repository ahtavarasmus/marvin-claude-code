#!/bin/bash
# Marvin is forced to relive old conversations
# Uses shuffled playlist (same approach as other hooks)

input=$(cat)

# Only play on resume, not fresh startup
source=$(echo "$input" | jq -r '.source // "startup"' 2>/dev/null)
if [ "$source" != "resume" ]; then
    exit 0
fi

# Check config - skip if disabled
CONFIG="$HOME/.config/marvin/config.json"
if [ -f "$CONFIG" ] && [ "$(jq -r '.resume // true' "$CONFIG" 2>/dev/null)" = "false" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PLAYLIST="$AUDIO_DIR/.resume_playlist"

if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_resume_*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

"$SCRIPT_DIR/marvin-play.sh" "$clip" "$AUDIO_DIR/.marvin_pid"

exit 0

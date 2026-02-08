#!/bin/bash
# Marvin reacts when a tool fails/errors
# Uses shuffled playlist (same approach as other hooks)

input=$(cat)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")/audio"
PLAYLIST="$AUDIO_DIR/.error_playlist"

if [ ! -s "$PLAYLIST" ]; then
    ls "$AUDIO_DIR"/marvin_error_*.mp3 2>/dev/null | sort -R > "$PLAYLIST"
fi

clip=$(head -1 "$PLAYLIST")
tail -n +2 "$PLAYLIST" > "$PLAYLIST.tmp" && mv "$PLAYLIST.tmp" "$PLAYLIST"

if [ -n "$clip" ] && [ -f "$clip" ]; then
    afplay "$clip" &
fi

exit 0
